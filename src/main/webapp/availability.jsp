<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List, com.meetingroom.Room" %>
<%
    if (session.getAttribute("user") == null) {
        response.sendRedirect(request.getContextPath() + "/index.jsp?msg=auth_required");
        return;
    }

    Boolean searched = (Boolean) request.getAttribute("searched");
    if (searched == null) searched = false;

    @SuppressWarnings("unchecked")
    List<Room> availableRooms = (List<Room>) request.getAttribute("availableRooms");

    String meetingDate = (String) request.getAttribute("meetingDate");
    String startTime = (String) request.getAttribute("startTime");
    String endTime = (String) request.getAttribute("endTime");
    String participants = (String) request.getAttribute("participants");
    String roomType = (String) request.getAttribute("roomType");
    String error = (String) request.getAttribute("error");

    if (meetingDate == null) meetingDate = "";
    if (startTime == null) startTime = "09:00";
    if (endTime == null) endTime = "10:00";
    if (participants == null) participants = "5";
    if (roomType == null) roomType = "All";
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Room Availability - MeetRoom Pro</title>
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

            <!-- Title Header -->
            <div class="d-flex justify-content-between align-items-center mb-4 flex-wrap gap-2">
                <div>
                    <h2 class="fw-bold mb-1"><i class="bi bi-search text-primary me-2"></i>Find Available Rooms</h2>
                    <p class="text-muted mb-0">Discover unoccupied conference rooms with real-time price rates and student discounts.</p>
                </div>
            </div>

            <!-- Error Notice -->
            <% if (error != null && !error.isEmpty()) { %>
                <div class="alert alert-danger alert-dismissible fade show" role="alert">
                    <i class="bi bi-exclamation-triangle-fill me-2"></i><%= error %>
                    <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                </div>
            <% } %>

            <!-- Search Filter Card -->
            <div class="card card-custom mb-4 border-0 shadow-sm">
                <div class="card-header-custom">
                    <span class="fw-bold"><i class="bi bi-sliders me-2 text-primary"></i>Availability &amp; Schedule Filter</span>
                </div>
                <div class="card-body p-4">
                    <form action="<%= request.getContextPath() %>/availability" method="get">
                        <div class="row g-3 align-items-end">
                            <div class="col-md-3 col-sm-6">
                                <label for="meetingDate" class="form-label fw-semibold">Meeting Date *</label>
                                <input type="date" name="meetingDate" id="meetingDate" class="form-control" value="<%= meetingDate %>" required>
                            </div>
                            <div class="col-md-2 col-sm-6">
                                <label for="startTime" class="form-label fw-semibold">Start Time *</label>
                                <input type="time" name="startTime" id="startTime" class="form-control" value="<%= startTime %>" required>
                            </div>
                            <div class="col-md-2 col-sm-6">
                                <label for="endTime" class="form-label fw-semibold">End Time *</label>
                                <input type="time" name="endTime" id="endTime" class="form-control" value="<%= endTime %>" required>
                            </div>
                            <div class="col-md-2 col-sm-6">
                                <label for="participants" class="form-label fw-semibold">Attendees</label>
                                <input type="number" name="participants" id="participants" class="form-control" min="1" max="500" value="<%= participants %>">
                            </div>
                            <div class="col-md-2 col-sm-6">
                                <label for="roomType" class="form-label fw-semibold">Room Type</label>
                                <select name="roomType" id="roomType" class="form-select">
                                    <option value="All" <%= "All".equals(roomType) ? "selected" : "" %>>All Types</option>
                                    <option value="Meeting Room" <%= "Meeting Room".equals(roomType) ? "selected" : "" %>>Meeting Room</option>
                                    <option value="Conference Room" <%= "Conference Room".equals(roomType) ? "selected" : "" %>>Conference Room</option>
                                    <option value="Board Room" <%= "Board Room".equals(roomType) ? "selected" : "" %>>Board Room</option>
                                    <option value="Huddle Room" <%= "Huddle Room".equals(roomType) ? "selected" : "" %>>Huddle Room</option>
                                    <option value="Seminar Room" <%= "Seminar Room".equals(roomType) ? "selected" : "" %>>Seminar Room</option>
                                </select>
                            </div>
                            <div class="col-md-1 col-sm-6">
                                <button type="submit" class="btn btn-primary w-100 shadow-sm" title="Search">
                                    <i class="bi bi-search"></i>
                                </button>
                            </div>
                        </div>
                    </form>
                </div>
            </div>

            <!-- Available Rooms Result Section -->
            <% if (searched) { %>
                <div class="d-flex justify-content-between align-items-center mb-3 flex-wrap gap-2">
                    <h5 class="fw-bold mb-0">
                        Available Rooms (<%= availableRooms != null ? availableRooms.size() : 0 %> found)
                    </h5>
                    <span class="badge bg-success bg-opacity-10 text-success border border-success border-opacity-25 px-3 py-2">
                        <i class="bi bi-clock me-1"></i> Slot: <%= meetingDate %> (<%= startTime %> - <%= endTime %>)
                    </span>
                </div>

                <% if (availableRooms == null || availableRooms.isEmpty()) { %>
                    <div class="card card-custom p-5 text-center border-0">
                        <i class="bi bi-calendar-x text-warning fs-1 mb-2"></i>
                        <h4 class="fw-bold">No Rooms Available for this Slot</h4>
                        <p class="text-muted">All rooms matching your capacity criteria are either booked during this time window or under maintenance.</p>
                        <div>
                            <a href="<%= request.getContextPath() %>/history" class="btn btn-outline-primary btn-sm">
                                Check Booking Schedule &rarr;
                            </a>
                        </div>
                    </div>
                <% } else { %>
                    <div class="row g-4">
                        <% 
                            String[] roomImages = {"meeting-room-hero.jpg", "meeting-room-1.jpg", "meeting-room-2.jpg", "meeting-room-3.jpg"};
                            for (Room r : availableRooms) { 
                                double studentRate = r.getHourlyRate() * 0.80;
                                String roomImg = roomImages[Math.abs(r.getRoomId()) % roomImages.length];
                        %>
                            <div class="col-md-6 col-lg-4">
                                <div class="card card-custom h-100 border-0 shadow-sm overflow-hidden">
                                    <div class="position-relative" style="height: 150px; overflow: hidden;">
                                        <img src="<%= request.getContextPath() %>/images/<%= roomImg %>" alt="<%= r.getRoomName() %>" class="w-100 h-100" style="object-fit: cover;">
                                        <span class="position-absolute top-0 end-0 m-2 badge-status badge-available shadow-sm">
                                            <i class="bi bi-check-circle-fill me-1"></i>Free
                                        </span>
                                        <span class="position-absolute bottom-0 start-0 m-2 badge bg-dark bg-opacity-75 text-white font-monospace">
                                            <%= r.getRoomNumber() %>
                                        </span>
                                    </div>
                                    <div class="card-body p-4 d-flex flex-column">
                                        <div class="mb-2">
                                            <h5 class="fw-bold mb-1"><%= r.getRoomName() %></h5>
                                            <div class="text-muted small">
                                                <i class="bi bi-geo-alt me-1"></i><%= r.getBuilding() %>, <%= r.getFloor() %>
                                            </div>
                                        </div>

                                        <!-- Pricing pill -->
                                        <div class="p-2 rounded-3 bg-secondary bg-opacity-10 border my-2 d-flex align-items-center justify-content-between">
                                            <div>
                                                <small class="text-muted d-block" style="font-size: 0.7rem;">Standard Rate</small>
                                                <strong class="text-primary">$<%= String.format("%.2f", r.getHourlyRate()) %>/hr</strong>
                                            </div>
                                            <div class="text-end">
                                                <span class="badge bg-success" style="font-size: 0.68rem;">Student 20% OFF</span>
                                                <div class="fw-bold text-success small">$<%= String.format("%.2f", studentRate) %>/hr</div>
                                            </div>
                                        </div>

                                        <div class="my-2 py-2 border-top border-bottom">
                                            <div class="row g-2 small text-muted">
                                                <div class="col-6">
                                                    <i class="bi bi-people-fill text-primary me-1"></i>
                                                    Capacity: <strong><%= r.getCapacity() %> seats</strong>
                                                </div>
                                                <div class="col-6">
                                                    <i class="bi bi-tag-fill text-secondary me-1"></i>
                                                    Type: <strong><%= r.getRoomType() %></strong>
                                                </div>
                                            </div>
                                        </div>

                                        <p class="small text-muted mb-4 flex-grow-1">
                                            <i class="bi bi-display me-1 text-info"></i>
                                            <strong>Amenities:</strong> <%= (r.getFacilities() != null && !r.getFacilities().isEmpty()) ? r.getFacilities() : "Standard equipment" %>
                                        </p>

                                        <!-- Pre-fill direct booking link -->
                                        <%
                                            String bookUrl = request.getContextPath() + "/bookings?roomId=" + r.getRoomId() +
                                                             "&date=" + meetingDate +
                                                             "&startTime=" + startTime +
                                                             "&endTime=" + endTime +
                                                             "&participants=" + participants;
                                        %>
                                        <a href="<%= bookUrl %>" class="btn btn-primary w-100 fw-semibold shadow-sm">
                                            <i class="bi bi-calendar-check me-1"></i> Book This Room
                                        </a>
                                    </div>
                                </div>
                            </div>
                        <% } %>
                    </div>
                <% } %>

            <% } else { %>
                <!-- Welcome prompt before search -->
                <div class="card card-custom p-5 text-center border-0">
                    <i class="bi bi-calendar2-range text-primary fs-1 mb-3"></i>
                    <h4 class="fw-bold">Check Real-Time Room Vacancies &amp; Hourly Rates</h4>
                    <p class="text-muted mx-auto" style="max-width: 500px;">
                        Select your preferred meeting date, start and end time above to see only the conference rooms that are 100% free and ready for reservation.
                    </p>
                </div>
            <% } %>

        </div>
    </div>

    <!-- Bootstrap 5 JS Bundle -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <script src="<%= request.getContextPath() %>/js/script.js"></script>
</body>
</html>
