<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, com.meetingroom.DatabaseConnection, java.util.*" %>
<%
    // Session Guard
    if (session.getAttribute("user") == null) {
        response.sendRedirect(request.getContextPath() + "/index.jsp?msg=auth_required");
        return;
    }
    String currentUser = (String) session.getAttribute("user");

    // Fetch dashboard stats from database
    int totalRooms = 0;
    int availableRooms = 0;
    int totalBookings = 0;
    int todayBookings = 0;
    double totalRevenue = 0.0;

    List<Map<String, String>> todayBookingList = new ArrayList<>();

    try (Connection conn = DatabaseConnection.getConnection()) {
        // Total rooms
        try (Statement s = conn.createStatement();
             ResultSet rs = s.executeQuery("SELECT COUNT(*) FROM rooms")) {
            if (rs.next()) totalRooms = rs.getInt(1);
        }

        // Available rooms
        try (Statement s = conn.createStatement();
             ResultSet rs = s.executeQuery("SELECT COUNT(*) FROM rooms WHERE status = 'Available'")) {
            if (rs.next()) availableRooms = rs.getInt(1);
        }

        // Total bookings
        try (Statement s = conn.createStatement();
             ResultSet rs = s.executeQuery("SELECT COUNT(*) FROM bookings WHERE booking_status = 'Booked'")) {
            if (rs.next()) totalBookings = rs.getInt(1);
        }

        // Today's bookings
        try (Statement s = conn.createStatement();
             ResultSet rs = s.executeQuery("SELECT COUNT(*) FROM bookings WHERE meeting_date = CURRENT_DATE() AND booking_status = 'Booked'")) {
            if (rs.next()) todayBookings = rs.getInt(1);
        }

        // Total Revenue / Booking value
        try (Statement s = conn.createStatement();
             ResultSet rs = s.executeQuery("SELECT COALESCE(SUM(total_amount), 0) FROM bookings WHERE booking_status = 'Booked'")) {
            if (rs.next()) totalRevenue = rs.getDouble(1);
        }

        // Today's schedule
        try (Statement s = conn.createStatement();
             ResultSet rs = s.executeQuery("SELECT booking_id, booking_number, room_name, room_number, meeting_title, employee_name, user_type, total_amount, payment_status, start_time, end_time, booking_status " +
                                          "FROM bookings WHERE meeting_date = CURRENT_DATE() AND booking_status = 'Booked' " +
                                          "ORDER BY start_time ASC LIMIT 6")) {
            while (rs.next()) {
                Map<String, String> b = new HashMap<>();
                b.put("id", String.valueOf(rs.getInt("booking_id")));
                b.put("number", rs.getString("booking_number"));
                b.put("room", rs.getString("room_name") + " (" + rs.getString("room_number") + ")");
                b.put("title", rs.getString("meeting_title"));
                b.put("employee", rs.getString("employee_name"));
                b.put("userType", rs.getString("user_type") != null ? rs.getString("user_type") : "General");
                b.put("amount", String.format("%.2f", rs.getDouble("total_amount")));
                b.put("paymentStatus", rs.getString("payment_status") != null ? rs.getString("payment_status") : "Pending");
                b.put("time", rs.getString("start_time").substring(0, 5) + " - " + rs.getString("end_time").substring(0, 5));
                b.put("status", rs.getString("booking_status"));
                todayBookingList.add(b);
            }
        }
    } catch (SQLException e) {
        e.printStackTrace();
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard - MeetRoom Pro</title>
    <!-- Bootstrap 5 CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <!-- Bootstrap Icons -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
    <!-- Custom CSS (with cache buster) -->
    <link href="<%= request.getContextPath() %>/css/style.css?v=3.1" rel="stylesheet">
</head>
<body>

    <!-- Main Left Sidebar & Mobile Navigation -->
    <%@ include file="sidebar.jsp" %>

    <div class="main-content">
        <div class="container-fluid">
            
            <!-- Hero Meeting Room Showcase Banner -->
            <div class="card card-custom border-0 overflow-hidden mb-4 shadow-sm position-relative text-white" style="min-height: 220px; border-radius: 16px;">
                <img src="<%= request.getContextPath() %>/images/meeting-room-hero.jpg" alt="Meeting Room" class="position-absolute top-0 start-0 w-100 h-100" style="object-fit: cover; filter: brightness(0.38);">
                <div class="card-body position-relative p-4 p-md-5 d-flex flex-column justify-content-between">
                    <div>
                        <div class="d-flex align-items-center gap-2 mb-2">
                            <span class="badge bg-primary px-3 py-1"><i class="bi bi-stars me-1"></i> Smart Facilities</span>
                            <span class="badge bg-warning text-dark px-3 py-1 fw-bold"><i class="bi bi-mortarboard-fill me-1"></i> 20% Student Subsidy</span>
                        </div>
                        <h2 class="fw-bold mb-2 text-white">Modern Meeting &amp; Conference Rooms</h2>
                        <p class="text-white-50 mb-3" style="max-width: 620px;">
                            Equipped with 4K projectors, high-speed Wi-Fi, video conferencing bars, and instant online &amp; offline booking.
                        </p>
                    </div>
                    <div class="d-flex flex-wrap gap-2">
                        <a href="<%= request.getContextPath() %>/bookings" class="btn btn-primary fw-semibold px-4 shadow">
                            <i class="bi bi-calendar-plus me-1"></i> Reserve Room Now
                        </a>
                        <a href="<%= request.getContextPath() %>/availability" class="btn btn-light fw-semibold px-4 shadow">
                            <i class="bi bi-search me-1"></i> Check Free Slots
                        </a>
                    </div>
                </div>
            </div>

            <!-- Welcome Header -->
            <div class="d-flex justify-content-between align-items-center mb-4 flex-wrap gap-2">
                <div>
                    <h2 class="fw-bold mb-1">Welcome back, <%= currentUser %>! <span class="fs-5">👋</span></h2>
                    <p class="text-muted mb-0">Overview of conference room operations, live pricing, and reservations.</p>
                </div>
                <div class="d-flex gap-2">
                    <a href="<%= request.getContextPath() %>/availability" class="btn btn-outline-primary shadow-sm">
                        <i class="bi bi-search me-1"></i> Check Free Rooms
                    </a>
                    <a href="<%= request.getContextPath() %>/bookings" class="btn btn-primary shadow-sm">
                        <i class="bi bi-calendar-plus me-1"></i> New Booking
                    </a>
                </div>
            </div>

            <!-- Metric Cards Row -->
            <div class="row g-3 mb-4">
                <div class="col-12 col-sm-6 col-xl-3">
                    <div class="stat-card d-flex align-items-center justify-content-between">
                        <div>
                            <div class="text-muted small fw-semibold text-uppercase">Total Rooms</div>
                            <h2 class="fw-bold mb-0 mt-1"><%= totalRooms %></h2>
                            <small class="text-success"><i class="bi bi-check2"></i> Registered rooms</small>
                        </div>
                        <div class="stat-icon bg-primary bg-opacity-10 text-primary">
                            <i class="bi bi-door-closed"></i>
                        </div>
                    </div>
                </div>

                <div class="col-12 col-sm-6 col-xl-3">
                    <div class="stat-card d-flex align-items-center justify-content-between">
                        <div>
                            <div class="text-muted small fw-semibold text-uppercase">Available Rooms</div>
                            <h2 class="fw-bold mb-0 text-success mt-1"><%= availableRooms %></h2>
                            <small class="text-muted">Ready for booking</small>
                        </div>
                        <div class="stat-icon bg-success bg-opacity-10 text-success">
                            <i class="bi bi-check-circle"></i>
                        </div>
                    </div>
                </div>

                <div class="col-12 col-sm-6 col-xl-3">
                    <div class="stat-card d-flex align-items-center justify-content-between">
                        <div>
                            <div class="text-muted small fw-semibold text-uppercase">Today's Bookings</div>
                            <h2 class="fw-bold mb-0 text-primary mt-1"><%= todayBookings %></h2>
                            <small class="text-muted">Scheduled today</small>
                        </div>
                        <div class="stat-icon bg-info bg-opacity-10 text-info">
                            <i class="bi bi-calendar-day"></i>
                        </div>
                    </div>
                </div>

                <div class="col-12 col-sm-6 col-xl-3">
                    <div class="stat-card d-flex align-items-center justify-content-between">
                        <div>
                            <div class="text-muted small fw-semibold text-uppercase">Booking Value</div>
                            <h2 class="fw-bold mb-0 text-warning mt-1">$<%= String.format("%.2f", totalRevenue) %></h2>
                            <small class="text-muted"><%= totalBookings %> total reservations</small>
                        </div>
                        <div class="stat-icon bg-warning bg-opacity-10 text-warning">
                            <i class="bi bi-currency-dollar"></i>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Quick Action Grid -->
            <div class="row g-4 mb-4">
                <div class="col-md-3">
                    <div class="card card-custom h-100 p-3 text-center border-0">
                        <div class="d-inline-flex align-items-center justify-content-center bg-primary bg-opacity-10 text-primary rounded-circle mx-auto mb-3" style="width: 56px; height: 56px;">
                            <i class="bi bi-door-open fs-3"></i>
                        </div>
                        <h5 class="fw-bold">Room Management</h5>
                        <p class="text-muted small mb-3">Add, update, or remove meeting rooms, capacity, and hourly rates.</p>
                        <a href="<%= request.getContextPath() %>/rooms" class="btn btn-outline-primary btn-sm mt-auto">Manage Rooms</a>
                    </div>
                </div>

                <div class="col-md-3">
                    <div class="card card-custom h-100 p-3 text-center border-0">
                        <div class="d-inline-flex align-items-center justify-content-center bg-success bg-opacity-10 text-success rounded-circle mx-auto mb-3" style="width: 56px; height: 56px;">
                            <i class="bi bi-calendar-plus fs-3"></i>
                        </div>
                        <h5 class="fw-bold">Instant Booking</h5>
                        <p class="text-muted small mb-3">Reserve rooms with live price calculation and Online/Offline payment.</p>
                        <a href="<%= request.getContextPath() %>/bookings" class="btn btn-outline-success btn-sm mt-auto">Book Now</a>
                    </div>
                </div>

                <div class="col-md-3">
                    <div class="card card-custom h-100 p-3 text-center border-0">
                        <div class="d-inline-flex align-items-center justify-content-center bg-info bg-opacity-10 text-info rounded-circle mx-auto mb-3" style="width: 56px; height: 56px;">
                            <i class="bi bi-search fs-3"></i>
                        </div>
                        <h5 class="fw-bold">Room Availability</h5>
                        <p class="text-muted small mb-3">Filter by date, time window, equipment, and seating capacity.</p>
                        <a href="<%= request.getContextPath() %>/availability" class="btn btn-outline-info btn-sm mt-auto">Check Availability</a>
                    </div>
                </div>

                <div class="col-md-3">
                    <div class="card card-custom h-100 p-3 text-center border-0">
                        <div class="d-inline-flex align-items-center justify-content-center bg-warning bg-opacity-10 text-warning rounded-circle mx-auto mb-3" style="width: 56px; height: 56px;">
                            <i class="bi bi-receipt-cutoff fs-3"></i>
                        </div>
                        <h5 class="fw-bold">Invoices &amp; History</h5>
                        <p class="text-muted small mb-3">Review all bookings, payment receipts, slips, and statuses.</p>
                        <a href="<%= request.getContextPath() %>/history" class="btn btn-outline-warning btn-sm mt-auto">View Invoices</a>
                    </div>
                </div>
            </div>

            <!-- Today's Schedule Table -->
            <div class="card card-custom mb-4 border-0">
                <div class="card-header-custom d-flex justify-content-between align-items-center">
                    <span class="fw-bold"><i class="bi bi-calendar-day me-2 text-primary"></i>Today's Meeting Schedule</span>
                    <a href="<%= request.getContextPath() %>/history?date=<%= new java.text.SimpleDateFormat("yyyy-MM-dd").format(new java.util.Date()) %>" class="btn btn-sm btn-link text-decoration-none">
                        View All Today's Bookings &rarr;
                    </a>
                </div>
                <div class="card-body p-0">
                    <div class="table-responsive">
                        <table class="table table-custom table-hover mb-0">
                            <thead>
                                <tr>
                                    <th>Ref #</th>
                                    <th>Meeting Title</th>
                                    <th>Room</th>
                                    <th>Organizer</th>
                                    <th>Category</th>
                                    <th>Cost / Payment</th>
                                    <th>Time Slot</th>
                                    <th>Status</th>
                                    <th class="text-end">Receipt</th>
                                </tr>
                            </thead>
                            <tbody>
                                <% if (todayBookingList.isEmpty()) { %>
                                    <tr>
                                        <td colspan="9" class="text-center py-4 text-muted">
                                            <i class="bi bi-calendar2-x fs-3 d-block mb-1"></i>
                                            No meetings scheduled for today yet.
                                        </td>
                                    </tr>
                                <% } else { %>
                                    <% for (Map<String, String> b : todayBookingList) { %>
                                        <tr>
                                            <td class="fw-bold font-monospace text-primary"><%= b.get("number") %></td>
                                            <td><strong><%= b.get("title") %></strong></td>
                                            <td><span class="badge bg-secondary bg-opacity-25 border"><%= b.get("room") %></span></td>
                                            <td><%= b.get("employee") %></td>
                                            <td><span class="badge bg-info bg-opacity-25 text-info border border-info border-opacity-25"><%= b.get("userType") %></span></td>
                                            <td>
                                                <div class="fw-semibold">$<%= b.get("amount") %></div>
                                                <small class="badge <%= "Paid".equalsIgnoreCase(b.get("paymentStatus")) ? "bg-success" : "bg-warning text-dark" %>" style="font-size: 0.65rem;">
                                                    <%= b.get("paymentStatus") %>
                                                </small>
                                            </td>
                                            <td><i class="bi bi-clock me-1 text-muted"></i><%= b.get("time") %></td>
                                            <td><span class="badge-status badge-booked"><%= b.get("status") %></span></td>
                                            <td class="text-end">
                                                <a href="<%= request.getContextPath() %>/receipt?bookingId=<%= b.get("id") %>" class="btn btn-outline-secondary btn-sm" title="View Slip">
                                                    <i class="bi bi-receipt"></i>
                                                </a>
                                            </td>
                                        </tr>
                                    <% } %>
                                <% } %>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>

        </div>
    </div>

    <!-- Bootstrap 5 JS Bundle -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <script src="<%= request.getContextPath() %>/js/script.js"></script>
</body>
</html>
