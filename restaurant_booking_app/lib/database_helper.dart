import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models/user.dart';
import 'models/menu_package.dart';
import 'models/booking.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('restaurant_booking.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Clear old data and reseed with new packages
      await db.delete('menu_packages');
      await _seedMenuPackages(db);
    }
    if (oldVersion < 3) {
      // Add email and phone columns to users table
      await db.execute('ALTER TABLE users ADD COLUMN email TEXT');
      await db.execute('ALTER TABLE users ADD COLUMN phone TEXT');
    }
    if (oldVersion < 4) {
      // Add serviceCustomizations column to bookings table
      await db.execute(
        'ALTER TABLE bookings ADD COLUMN serviceCustomizations TEXT',
      );
    }
  }

  Future<void> _createDB(Database db, int version) async {
    // Create users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        role TEXT NOT NULL,
        email TEXT,
        phone TEXT
      )
    ''');

    // Create menu_packages table
    await db.execute('''
      CREATE TABLE menu_packages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        pricePerGuest REAL NOT NULL,
        imageUrl TEXT NOT NULL
      )
    ''');

    // Create bookings table
    await db.execute('''
      CREATE TABLE bookings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        packageId INTEGER NOT NULL,
        eventDate TEXT NOT NULL,
        eventTime TEXT NOT NULL,
        numberOfGuests INTEGER NOT NULL,
        totalPrice REAL NOT NULL,
        status TEXT NOT NULL,
        serviceCustomizations TEXT,
        FOREIGN KEY (userId) REFERENCES users (id),
        FOREIGN KEY (packageId) REFERENCES menu_packages (id)
      )
    ''');

    // Insert default admin user
    await db.insert('users', {
      'username': 'admin',
      'password': 'admin123',
      'role': 'admin',
    });

    // Insert sample menu packages
    await _seedMenuPackages(db);
  }

  Future<void> _seedMenuPackages(Database db) async {
    await db.insert('menu_packages', {
      'name': 'Bronze Package',
      'description':
          'Starter package ideal for casual gatherings with light snacks and beverages.',
      'pricePerGuest': 30.0,
      'imageUrl':
          'https://images.unsplash.com/photo-1555244162-803834f70033?w=800&q=80',
    });

    await db.insert('menu_packages', {
      'name': 'Silver Package',
      'description':
          'Perfect for intimate gatherings with appetizers, main course, and dessert.',
      'pricePerGuest': 45.0,
      'imageUrl':
          'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=800&q=80',
    });

    await db.insert('menu_packages', {
      'name': 'Gold Package',
      'description':
          'Elegant dining experience with premium selections, wine pairing, and exclusive service.',
      'pricePerGuest': 75.0,
      'imageUrl':
          'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=800&q=80',
    });

    await db.insert('menu_packages', {
      'name': 'Platinum Package',
      'description':
          'Luxury all-inclusive experience with champagne, five-course meal, and personalized service.',
      'pricePerGuest': 120.0,
      'imageUrl':
          'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=800&q=80',
    });

    await db.insert('menu_packages', {
      'name': 'Diamond Package',
      'description':
          'Ultimate VIP experience featuring caviar, truffle-infused dishes, and Michelin-star chef service.',
      'pricePerGuest': 180.0,
      'imageUrl':
          'https://images.unsplash.com/photo-1559339352-11d035aa65de?w=800&q=80',
    });

    await db.insert('menu_packages', {
      'name': 'Seafood Deluxe',
      'description':
          'Fresh ocean delicacies with lobster, prawns, oysters, and grilled fish specialties.',
      'pricePerGuest': 95.0,
      'imageUrl':
          'https://images.unsplash.com/photo-1559339352-11d035aa65de?w=800&q=80',
    });

    await db.insert('menu_packages', {
      'name': 'Asian Fusion',
      'description':
          'Exquisite blend of Japanese sushi, Chinese dim sum, and Thai curry selections.',
      'pricePerGuest': 65.0,
      'imageUrl':
          'https://images.unsplash.com/photo-1534422298391-e4f8c172dddb?w=800&q=80',
    });

    await db.insert('menu_packages', {
      'name': 'Mediterranean Feast',
      'description':
          'Greek and Italian inspired menu with fresh salads, pasta, grilled meats, and olive oils.',
      'pricePerGuest': 70.0,
      'imageUrl':
          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800&q=80',
    });

    await db.insert('menu_packages', {
      'name': 'BBQ & Grill',
      'description':
          'American-style barbecue with premium steaks, ribs, grilled vegetables, and signature sauces.',
      'pricePerGuest': 85.0,
      'imageUrl':
          'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=800&q=80',
    });

    await db.insert('menu_packages', {
      'name': 'Vegetarian Delight',
      'description':
          'Plant-based gourmet cuisine with organic vegetables, quinoa bowls, and artisan breads.',
      'pricePerGuest': 55.0,
      'imageUrl':
          'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800&q=80',
    });
  }

  // User operations
  Future<User?> getUser(String username, String password) async {
    final db = await database;
    try {
      final maps = await db.query(
        'users',
        where: 'username = ? AND password = ?',
        whereArgs: [username, password],
      );

      if (maps.isNotEmpty) {
        return User.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  Future<User?> getUserByUsername(String username) async {
    final db = await database;
    try {
      final maps = await db.query(
        'users',
        where: 'username = ?',
        whereArgs: [username],
      );

      if (maps.isNotEmpty) {
        return User.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('Error getting user by username: $e');
      return null;
    }
  }

  Future<int> insertUser(User user) async {
    final db = await database;
    try {
      return await db.insert('users', user.toMap());
    } catch (e) {
      print('Error inserting user: $e');
      return -1;
    }
  }

  Future<List<User>> getAllUsers() async {
    final db = await database;
    try {
      final maps = await db.query('users');
      return maps.map((map) => User.fromMap(map)).toList();
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    try {
      return await db.delete('users', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      print('Error deleting user: $e');
      return 0;
    }
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    try {
      return await db.update(
        'users',
        user.toMap(),
        where: 'id = ?',
        whereArgs: [user.id],
      );
    } catch (e) {
      print('Error updating user: $e');
      return 0;
    }
  }

  // Menu package operations
  Future<List<MenuPackage>> getAllMenuPackages() async {
    final db = await database;
    try {
      final maps = await db.query('menu_packages');
      return maps.map((map) => MenuPackage.fromMap(map)).toList();
    } catch (e) {
      print('Error getting menu packages: $e');
      return [];
    }
  }

  Future<MenuPackage?> getMenuPackage(int id) async {
    final db = await database;
    try {
      final maps = await db.query(
        'menu_packages',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        return MenuPackage.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('Error getting menu package: $e');
      return null;
    }
  }

  Future<int> insertMenuPackage(MenuPackage package) async {
    final db = await database;
    try {
      return await db.insert('menu_packages', package.toMap());
    } catch (e) {
      print('Error inserting menu package: $e');
      return -1;
    }
  }

  Future<int> updateMenuPackage(MenuPackage package) async {
    final db = await database;
    try {
      return await db.update(
        'menu_packages',
        package.toMap(),
        where: 'id = ?',
        whereArgs: [package.id],
      );
    } catch (e) {
      print('Error updating menu package: $e');
      return 0;
    }
  }

  Future<int> deleteMenuPackage(int id) async {
    final db = await database;
    try {
      return await db.delete('menu_packages', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      print('Error deleting menu package: $e');
      return 0;
    }
  }

  // Booking operations
  Future<List<Booking>> getBookings({int? userId}) async {
    final db = await database;
    try {
      List<Map<String, dynamic>> maps;
      if (userId != null) {
        maps = await db.query(
          'bookings',
          where: 'userId = ?',
          whereArgs: [userId],
        );
      } else {
        maps = await db.query('bookings');
      }
      return maps.map((map) => Booking.fromMap(map)).toList();
    } catch (e) {
      print('Error getting bookings: $e');
      return [];
    }
  }

  Future<Booking?> getBooking(int id) async {
    final db = await database;
    try {
      final maps = await db.query('bookings', where: 'id = ?', whereArgs: [id]);

      if (maps.isNotEmpty) {
        return Booking.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('Error getting booking: $e');
      return null;
    }
  }

  Future<int> insertBooking(Booking booking) async {
    final db = await database;
    try {
      return await db.insert('bookings', booking.toMap());
    } catch (e) {
      print('Error inserting booking: $e');
      return -1;
    }
  }

  Future<int> updateBooking(Booking booking) async {
    final db = await database;
    try {
      return await db.update(
        'bookings',
        booking.toMap(),
        where: 'id = ?',
        whereArgs: [booking.id],
      );
    } catch (e) {
      print('Error updating booking: $e');
      return 0;
    }
  }

  Future<int> deleteBooking(int id) async {
    final db = await database;
    try {
      return await db.delete('bookings', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      print('Error deleting booking: $e');
      return 0;
    }
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
