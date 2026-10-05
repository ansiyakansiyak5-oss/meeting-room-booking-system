# Meeting Room Booking System

A complete, beginner-friendly, cloud-ready web application built with **pure Java Servlets + JSP + JDBC** and styled with modern **Bootstrap 5**. Designed specifically for easy, zero-hassle cloud deployment on **Render** or **Railway** with an external **Aiven Cloud MySQL** database.

---

## Tech Stack (Strictly Pure Java - No Frameworks)

- **Backend:** Java Servlets (Jakarta EE)
- **View / Presentation:** JSP (JavaServer Pages) + JSTL
- **Database Access:** JDBC + MySQL Connector/J (PreparedStatements)
- **Database:** MySQL 8.x (Hosted on Aiven Cloud with SSL)
- **Frontend:** HTML5, CSS3, JavaScript (ES6+), Bootstrap 5.3, Bootstrap Icons
- **Packaging:** Runnable / Deployable `.war` file (Apache Tomcat 10.1+)
- **Cloud Deployment:** Ready for **Render** and **Railway** via automated multi-stage `Dockerfile`

---

## Key Features

1. **Secure Authentication & Session Management:**
   - Default administrator account pre-configured (`admin` / `admin123`).
   - Protected routes and session timeout safeguards.
2. **Dashboard Overview:**
   - Real-time KPI statistics: Total Rooms, Available Rooms, Today's Meetings, Active Bookings.
   - Schedule preview table for the current date.
3. **Full Room Management (CRUD):**
   - Add, edit, list, and delete rooms.
   - Configure capacity, building, floor, room type, and amenities.
   - Toggle status between **Available** and **Maintenance**.
   - **Protection against active booking deletion**: Rooms with active or upcoming bookings cannot be accidentally deleted.
4. **Meeting Room Booking with Critical Conflict Detection:**
   - Auto-generates unique human-readable booking numbers (`BK-YYYYMMDD-XXXX`).
   - Prevents meeting conflicts using the exact formula:
     $$\text{existing.start\_time} < \text{new.end\_time} \quad \text{AND} \quad \text{existing.end\_time} > \text{new.start\_time}$$
   - Displays clear error feedback specifying who booked the conflicting slot and when.
   - Capacity validation ensures attendee count $\le$ room capacity.
5. **Real-Time Room Availability Search:**
   - Filter by date, time window, and required seating capacity.
   - Shows only unoccupied rooms and provides a 1-click **"Book This Room"** button with all data pre-filled.
6. **Booking History:**
   - Searchable by reference number, organizer name, department, title, or room.
   - Filter by status (`Booked`, `Cancelled`, `Completed`) and date.
   - Actions to view slips, edit reservations, cancel, or delete records.
7. **Booking Receipt Slip:**
   - Clean confirmation view for employees.
   - **Print** button (`window.print()`) formatted with custom print CSS.
   - **Save as .txt** download button for client-side and server-side text receipts.

---

## Project Structure

```
MeetingRoomBookingSystem/
├── src/
│   ├── main/
│   │   ├── java/com/meetingroom/
│   │   │   ├── DatabaseConnection.java   # Aiven MySQL connection & auto-table initializer
│   │   │   ├── LoginServlet.java         # Authentication & session invalidation
│   │   │   ├── RoomServlet.java          # Room CRUD & deletion safeguards
│   │   │   ├── BookingServlet.java       # Booking CRUD & conflict detection engine
│   │   │   ├── AvailabilityServlet.java  # Vacancy search & pre-filling
│   │   │   ├── HistoryServlet.java       # Booking log & search filters
│   │   │   ├── ReceiptServlet.java       # Receipt slip & .txt generator
│   │   │   ├── Room.java                 # Entity model
│   │   │   ├── Booking.java              # Entity model
│   │   │   └── User.java                 # Entity model
│   │   └── webapp/
│   │       ├── WEB-INF/
│   │       │   ├── web.xml               # Servlet mappings & session config
│   │       │   └── lib/
│   │       │       └── mysql-connector-j-8.4.0.jar
│   │       ├── css/
│   │       │   └── style.css             # Modern styling & print media rules
│   │       ├── js/
│   │       │   └── script.js             # Client validation & modal helpers
│   │       ├── navbar.jsp                # Unified header navigation
│   │       ├── index.jsp                 # Login portal
│   │       ├── dashboard.jsp             # Metrics & operational dashboard
│   │       ├── room-management.jsp       # Room CRUD & equipment setup
│   │       ├── booking.jsp               # Meeting reservation form
│   │       ├── availability.jsp          # Vacancy finder
│   │       ├── history.jsp               # Booking records table
│   │       └── receipt.jsp               # Printable slip & TXT download
├── database/
│   └── meeting_room_booking_system.sql   # DDL script & sample rooms
├── Dockerfile                            # Multi-stage build for Render / Railway
├── pom.xml                               # Maven build configuration
├── build.bat                             # Windows 1-click compile & WAR packager
├── build.ps1                             # PowerShell build script
└── README.md                             # Documentation & deployment guide
```

---

## Database Configuration (Aiven MySQL)

### 1. Create a MySQL Service on Aiven
1. Sign up or log into [Aiven.io](https://aiven.io/).
2. Create a new **MySQL** service (the free trial or small plan is perfect).
3. Wait until the service status turns **Running**.
4. In the service **Overview** tab, copy the connection details:
   - **Host:** e.g., `mysql-xxxx-project.aivencloud.com`
   - **Port:** e.g., `12345`
   - **User:** e.g., `avnadmin`
   - **Password:** `<your-aiven-password>`
   - **Database:** `defaultdb`

### 2. Environment Variables Reference
The application automatically reads these environment variables from your system or cloud provider:

| Variable Name | Description | Example Value |
|---|---|---|
| `DB_HOST` | Aiven MySQL hostname | `mysql-xxxx.aivencloud.com` |
| `DB_PORT` | Aiven MySQL port | `12345` |
| `DB_NAME` | Database catalog name | `defaultdb` |
| `DB_USER` | MySQL username | `avnadmin` |
| `DB_PASSWORD` | MySQL password | `secret_password` |
| `DB_SSL` | Force SSL connection | `REQUIRED` (or `true`) |
| `DATABASE_URL` | *Alternative single URL* | `mysql://avnadmin:pass@host:port/defaultdb` |

> **Note:** If you provide `DATABASE_URL` or `MYSQL_URL` (often auto-provided by Railway or Render), the application automatically parses it!

### 3. Automatic Table Initialization
`DatabaseConnection.java` automatically runs `CREATE TABLE IF NOT EXISTS` and inserts the default admin (`admin` / `admin123`) and sample rooms on first boot. You do **not** need to manually run SQL scripts, though the complete SQL script is also provided at `database/meeting_room_booking_system.sql`.

---

## Testing Database Connection Locally

You can test your Aiven credentials directly from your terminal before deploying:

```powershell
# In PowerShell:
$env:DB_HOST="your-aiven-host.aivencloud.com"
$env:DB_PORT="12345"
$env:DB_NAME="defaultdb"
$env:DB_USER="avnadmin"
$env:DB_PASSWORD="your-password"

java -cp "target/classes;lib/*" com.meetingroom.DatabaseConnection
```

---

## Local Build & Packaging

To compile all Java classes and build `target/meetingroom.war` on Windows:

```powershell
# Using PowerShell:
.\build.ps1

# Or using batch file:
.\build.bat
```

To build with Maven (if Maven is installed):
```bash
mvn clean package -DskipTests
```

---

## Deployment to Render

Deploying on [Render](https://render.com) takes under 3 minutes:

1. Push this repository to **GitHub** or **GitLab**.
2. Log into **Render** and click **New +** $\rightarrow$ **Web Service**.
3. Select your repository.
4. Set the following options:
   - **Name:** `meeting-room-system`
   - **Region:** Choose a region close to your Aiven MySQL database.
   - **Environment:** **Docker** (Render will automatically detect the `Dockerfile` in the root).
   - **Plan:** Free or Starter.
5. In the **Environment Variables** section, add your Aiven credentials:
   - `DB_HOST` = `your-aiven-host.aivencloud.com`
   - `DB_PORT` = `your-aiven-port`
   - `DB_NAME` = `defaultdb`
   - `DB_USER` = `avnadmin`
   - `DB_PASSWORD` = `your-aiven-password`
   - `DB_SSL` = `REQUIRED`
6. Click **Create Web Service**.
7. Render will build the Docker container and start Tomcat. Open your Render URL (e.g., `https://meeting-room-system.onrender.com`) to access the app!

---

## Deployment to Railway

Deploying on [Railway](https://railway.app):

1. Log into **Railway** and click **New Project**.
2. Select **Deploy from GitHub repo** and choose this repository.
3. Railway automatically detects the `Dockerfile`.
4. Go to **Variables** tab for the service and add:
   - `DB_HOST` = `your-aiven-host.aivencloud.com`
   - `DB_PORT` = `your-aiven-port`
   - `DB_NAME` = `defaultdb`
   - `DB_USER` = `avnadmin`
   - `DB_PASSWORD` = `your-aiven-password`
   - `DB_SSL` = `REQUIRED`
5. Go to **Settings** $\rightarrow$ **Networking** $\rightarrow$ Click **Generate Domain**.
6. Railway assigns a public URL (e.g. `https://xxx.up.railway.app`). Open it in your browser!

---

## Default Login Credentials

- **Username:** `admin`
- **Password:** `admin123`

You can change these credentials or add more administrators in the `users` table.

---

## Conflict Detection Logic Explained

To guarantee that meeting rooms are never double-booked:

When a reservation is submitted for room $R$ on date $D$ from $S_{\text{new}}$ to $E_{\text{new}}$, the system executes:

```sql
SELECT booking_number, meeting_title, employee_name, start_time, end_time
FROM bookings
WHERE room_id = ?
  AND meeting_date = ?
  AND booking_status = 'Booked'
  AND (start_time < ? AND end_time > ?)
```

Where:
- First parameter `?`: Room ID
- Second parameter `?`: Meeting Date
- Third parameter `?`: Requested End Time ($E_{\text{new}}$)
- Fourth parameter `?`: Requested Start Time ($S_{\text{new}}$)
- (When updating an existing booking, `AND booking_id != ?` excludes itself)

If any overlapping row is returned, the booking is rejected with an informative error message showing the conflict details.
