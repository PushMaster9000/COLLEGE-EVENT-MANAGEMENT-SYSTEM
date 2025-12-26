const express = require('express');
const mysql = require('mysql2/promise');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const cors = require('cors');
const path = require('path');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static('.'));

// Database connection
const db = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || 'haha',
  database: process.env.DB_NAME || 'college_event_management',
  waitForConnections: true,
  connectionLimit: 10,
});

// JWT Secret
const JWT_SECRET = process.env.JWT_SECRET || 'fallback-secret';

// Authentication middleware
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ error: 'Invalid token' });
    }
    req.user = user;
    next();
  });
};

// Organizer authentication middleware
const authenticateOrganiser = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }

  jwt.verify(token, JWT_SECRET, (err, organiser) => {
    if (err) {
      return res.status(403).json({ error: 'Invalid token' });
    }
    
    if (organiser.role !== 'organiser') {
      return res.status(403).json({ error: 'Access denied. Organiser role required.' });
    }
    
    req.organiser = organiser;
    next();
  });
};

// Serve frontend
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

// Test database connection
app.get('/api/test', async (req, res) => {
  try {
    const [rows] = await db.execute('SELECT 1 + 1 AS solution');
    res.json({ message: 'Database connected!', result: rows[0].solution });
  } catch (error) {
    res.status(500).json({ error: 'Database connection failed' });
  }
});

// Get all events (accessible to all)
app.get('/api/events', async (req, res) => {
  try {
    const [events] = await db.execute(`
      SELECT e.*, u.name as organizer_name 
      FROM events e 
      LEFT JOIN users u ON e.organizer_id = u.user_id 
      ORDER BY e.date
    `);
    res.json({ events });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch events' });
  }
});

// Get events by organiser
app.get('/api/organiser/events', authenticateOrganiser, async (req, res) => {
  try {
    const organiserId = req.organiser.organiserId;
    
    const [events] = await db.execute(`
      SELECT e.*, 
             COUNT(r.registration_id) as registration_count,
             (SELECT COUNT(*) FROM registrations r2 WHERE r2.event_id = e.event_id AND r2.status = 'confirmed') as confirmed_registrations
      FROM events e 
      LEFT JOIN registrations r ON e.event_id = r.event_id
      WHERE e.organizer_id = ?
      GROUP BY e.event_id
      ORDER BY e.date
    `, [organiserId]);
    
    res.json({ events });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch organiser events' });
  }
});

// Organiser registration
app.post('/api/organiser/register', async (req, res) => {
  try {
    console.log('Organiser registration attempt:', req.body);
    
    const { name, email, password, department, phone } = req.body;
    
    if (!name || !email || !password || !department) {
      return res.status(400).json({ 
        success: false, 
        error: 'All fields are required' 
      });
    }

    // Check if organiser already exists
    const [existingOrganisers] = await db.execute(
      'SELECT * FROM organisers WHERE email = ?',
      [email]
    );

    console.log('Existing organisers check:', existingOrganisers);

    if (existingOrganisers.length > 0) {
      return res.status(400).json({ 
        success: false, 
        error: 'Organiser with this email already exists' 
      });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);
    console.log('Password hashed successfully');

    // Insert organiser
    const [result] = await db.execute(
      'INSERT INTO organisers (name, email, password, department, phone) VALUES (?, ?, ?, ?, ?)',
      [name, email, hashedPassword, department, phone]
    );

    console.log('Organiser inserted with ID:', result.insertId);

    // Generate JWT token
    const token = jwt.sign(
      { organiserId: result.insertId, email: email, role: 'organiser' },
      JWT_SECRET,
      { expiresIn: '24h' }
    );

    res.json({
      success: true,
      message: 'Organiser registered successfully',
      token,
      organiser: {
        id: result.insertId,
        name,
        email,
        department,
        phone,
        role: 'organiser'
      }
    });
  } catch (error) {
    console.error('Organiser registration error:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Registration failed: ' + error.message 
    });
  }
});

// Organiser login
app.post('/api/organiser/login', async (req, res) => {
  try {
    console.log('Organiser login attempt:', req.body);
    
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ 
        success: false, 
        error: 'Email and password are required' 
      });
    }

    // Find organiser
    const [organisers] = await db.execute(
      'SELECT * FROM organisers WHERE email = ?',
      [email]
    );

    console.log('Found organisers:', organisers);

    if (organisers.length === 0) {
      return res.status(401).json({ 
        success: false, 
        error: 'Invalid email or password' 
      });
    }

    const organiser = organisers[0];
    console.log('Organiser found:', organiser);

    // Check password
    const validPassword = await bcrypt.compare(password, organiser.password);
    console.log('Password valid:', validPassword);

    if (!validPassword) {
      return res.status(401).json({ 
        success: false, 
        error: 'Invalid email or password' 
      });
    }

    // Generate JWT token
    const token = jwt.sign(
      { organiserId: organiser.organiser_id, email: organiser.email, role: 'organiser' },
      JWT_SECRET,
      { expiresIn: '24h' }
    );

    console.log('Login successful, token generated');

    res.json({
      success: true,
      message: 'Login successful',
      token,
      organiser: {
        id: organiser.organiser_id,
        name: organiser.name,
        email: organiser.email,
        department: organiser.department,
        phone: organiser.phone,
        role: 'organiser'
      }
    });
  } catch (error) {
    console.error('Organiser login error:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Login failed: ' + error.message 
    });
  }
});

// Create event - ONLY FOR ORGANISERS
app.post('/api/events', authenticateOrganiser, async (req, res) => {
  try {
    const { title, description, date, time, location, category, capacity } = req.body;
    
    // Use the logged-in organiser as organizer
    const [result] = await db.execute(
      'INSERT INTO events (title, description, date, time, location, category, capacity, organizer_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      [title, description, date, time, location, category, capacity, req.organiser.organiserId]
    );

    res.json({
      success: true,
      message: 'Event created successfully',
      eventId: result.insertId
    });
  } catch (error) {
    console.error('Create event error:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Event creation failed: ' + error.message 
    });
  }
});

// Update event - ONLY FOR ORGANISERS
app.put('/api/events/:id', authenticateOrganiser, async (req, res) => {
  try {
    const eventId = req.params.id;
    const { title, description, date, time, location, category, capacity } = req.body;
    
    // Verify that the event belongs to the organiser
    const [events] = await db.execute(
      'SELECT * FROM events WHERE event_id = ? AND organizer_id = ?',
      [eventId, req.organiser.organiserId]
    );

    if (events.length === 0) {
      return res.status(404).json({ 
        success: false, 
        error: 'Event not found or access denied' 
      });
    }

    // Update event
    await db.execute(
      'UPDATE events SET title = ?, description = ?, date = ?, time = ?, location = ?, category = ?, capacity = ? WHERE event_id = ?',
      [title, description, date, time, location, category, capacity, eventId]
    );

    res.json({
      success: true,
      message: 'Event updated successfully'
    });
  } catch (error) {
    console.error('Update event error:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Event update failed: ' + error.message 
    });
  }
});

// Delete event - ONLY FOR ORGANISERS
app.delete('/api/events/:id', authenticateOrganiser, async (req, res) => {
  try {
    const eventId = req.params.id;
    
    // Verify that the event belongs to the organiser
    const [events] = await db.execute(
      'SELECT * FROM events WHERE event_id = ? AND organizer_id = ?',
      [eventId, req.organiser.organiserId]
    );

    if (events.length === 0) {
      return res.status(404).json({ 
        success: false, 
        error: 'Event not found or access denied' 
      });
    }

    // Delete event (cascade delete will handle registrations)
    await db.execute(
      'DELETE FROM events WHERE event_id = ?',
      [eventId]
    );

    res.json({
      success: true,
      message: 'Event deleted successfully'
    });
  } catch (error) {
    console.error('Delete event error:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Event deletion failed: ' + error.message 
    });
  }
});

// Register for event - FOR STUDENTS (existing functionality)
app.post('/api/events/:id/register', authenticateToken, async (req, res) => {
  try {
    const eventId = req.params.id;
    const userId = req.user.userId;

    // Check if user is a student
    const [users] = await db.execute(
      'SELECT role FROM users WHERE user_id = ?',
      [userId]
    );

    if (users.length === 0 || users[0].role !== 'student') {
      return res.status(403).json({ 
        success: false, 
        error: 'Only students can register for events' 
      });
    }

    // Check if already registered
    const [existing] = await db.execute(
      'SELECT * FROM registrations WHERE user_id = ? AND event_id = ?',
      [userId, eventId]
    );

    if (existing.length > 0) {
      return res.status(400).json({ 
        success: false, 
        error: 'Already registered for this event' 
      });
    }

    // Register for event
    const [result] = await db.execute(
      'INSERT INTO registrations (user_id, event_id, status) VALUES (?, ?, ?)',
      [userId, eventId, 'confirmed']
    );

    res.json({
      success: true,
      message: 'Successfully registered for event',
      registrationId: result.insertId
    });
  } catch (error) {
    console.error('Event registration error:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Registration failed: ' + error.message 
    });
  }
});

// User registration - FIXED (students only)
app.post('/api/register', async (req, res) => {
  try {
    const { name, email, password, department, year } = req.body;
    
    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Insert user as student
    const [result] = await db.execute(
      'INSERT INTO users (name, email, password, department, year, role) VALUES (?, ?, ?, ?, ?, ?)',
      [name, email, hashedPassword, department, year, 'student']
    );

    // Generate JWT token
    const token = jwt.sign(
      { userId: result.insertId, email: email, role: 'student' },
      JWT_SECRET,
      { expiresIn: '24h' }
    );

    res.json({
      success: true,
      message: 'User registered successfully',
      token,
      user: {
        id: result.insertId,
        name,
        email,
        department,
        year,
        role: 'student'
      }
    });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Registration failed: ' + error.message 
    });
  }
});

// User login - FIXED
app.post('/api/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    // Find user
    const [users] = await db.execute(
      'SELECT * FROM users WHERE email = ?',
      [email]
    );

    if (users.length === 0) {
      return res.status(401).json({ 
        success: false, 
        error: 'Invalid email or password' 
      });
    }

    const user = users[0];

    // Check password
    const validPassword = await bcrypt.compare(password, user.password);
    if (!validPassword) {
      return res.status(401).json({ 
        success: false, 
        error: 'Invalid email or password' 
      });
    }

    // Generate JWT token
    const token = jwt.sign(
      { userId: user.user_id, email: user.email, role: user.role },
      JWT_SECRET,
      { expiresIn: '24h' }
    );

    res.json({
      success: true,
      message: 'Login successful',
      token,
      user: {
        id: user.user_id,
        name: user.name,
        email: user.email,
        role: user.role,
        department: user.department,
        year: user.year
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Login failed: ' + error.message 
    });
  }
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
  console.log('✅ Database imported successfully!');
  console.log('📊 Test the API: http://localhost:3000/api/test');
  console.log('📅 Events API: http://localhost:3000/api/events');
  console.log('🏠 Main app: http://localhost:3000/');
});

// Error handling
process.on('uncaughtException', (error) => {
  console.log('❌ Uncaught Exception:', error.message);
});

process.on('unhandledRejection', (reason, promise) => {
  console.log('❌ Unhandled Rejection at:', promise, 'reason:', reason);
});
// Add this route to create organisers table (easier to access)
app.get('/api/create-organisers-table', async (req, res) => {
  try {
    // Create organisers table
    await db.execute(`
      CREATE TABLE IF NOT EXISTS organisers (
        organiser_id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        email VARCHAR(100) UNIQUE NOT NULL,
        password VARCHAR(255) NOT NULL,
        department VARCHAR(50) NOT NULL,
        phone VARCHAR(15),
        is_active BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )
    `);

    // Insert sample organisers
    await db.execute(`
      INSERT IGNORE INTO organisers (name, email, password, department, phone) VALUES
      ('Prof. Sharma', 'sharma@college.edu', '$2b$10$examplehashedpassword', 'Computer Science', '9876543211'),
      ('Dr. Verma', 'verma@college.edu', '$2b$10$examplehashedpassword', 'Electronics', '9876543212')
    `);

    res.json({ 
      success: true, 
      message: 'Organisers table created successfully with sample data' 
    });
  } catch (error) {
    console.error('Error creating organisers table:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to create organisers table: ' + error.message 
    });
  }
});