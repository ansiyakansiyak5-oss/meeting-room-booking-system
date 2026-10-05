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
    <title>Room Availability - Meeting Room Booking System</title>
    <!-- Bootstrap 5 CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <!-- Bootstrap Icons -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
    <!-- Custom CSS -->
    <link href="<%= request.getContextPath() %>/css/style.css" rel="stylesheet">
</head>
<body>

    <!-- Header Navigation -->
    <%@ include file="navbar.jsp" %>

    <div class="main-content">
        <div class="container-fluid px-4">

            <!-- Title Header -->
            <div class="d-flex justify-content-between align-items-center mb-4 flex-wrap gap-2">
                <div>
                    <h2 class="fw-bold mb-1 text-dark"><i class="bi bi-search text-primary me-2"></i>Find Available Rooms</h2>
                    <p class="text-muted mb-0">Discover unoccupied conference spaces that match your schedule and team size.</p>
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
                <div class="card-header-custom bg-white">
                    <span class="fw-bold text-dark"><i class="bi bi-sliders me-2 text-primary"></i>Availability Criteria</span>
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
                                <label for="participants" class="form-label fw-semibold">Min Capacity</label>
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
                                <button type="submit" class="btn btn-primary w-100">
                                    <i class="bi bi-search"></i>
                                </button>
                            </div>
                        </div>
                    </form>
                </div>
            </div>

            <!-- Available Rooms Result Section -->
            <% if (searched) { %>
                <div class="d-flex justify-content-between align-items-center mb-3">
                    <h5 class="fw-bold text-dark mb-0">
                        Available Rooms (<%= availableRooms != null ? availableRooms.size() : 0 %> found)
                    </h5>
                    <span class="badge bg-success-subtle text-success border border-success-subtle px-3 py-2">
                        <i class="bi bi-clock me-1"></i> Slot: <%= meetingDate %> (<%= startTime %> - <%= endTime %>)
                    </span>
                </div>

                <% if (availableRooms == null || availableRooms.isEmpty()) { %>
                    <div class="card card-custom p-5 text-center border-0">
                        <i class="bi bi-calendar-x text-warning fs-1 mb-2"></i>
                        <h4 class="fw-bold text-dark">No Rooms Available for this Slot</h4>
                        <p class="text-muted">All rooms matching your capacity criteria are either booked during this time slot or under maintenance.</p>
                        <div>
                            <a href="<%= request.getContextPath() %>/history" class="btn btn-outline-primary btn-sm">
                                Check Booking Schedule &rarr;
                            </a>
                        </div>
                    </div>
                <% } else { %>
                    <div class="row g-4">
                        <% for (Room r : availableRooms) { %>
                            <div class="col-md-6 col-lg-4">
                                <div class="card card-custom h-100 border-0 shadow-sm">
                                    <div class="card-body p-4 d-flex flex-column">
                                        <div class="d-flex justify-content-between align-items-start mb-2">
                                            <div>
                                                <span class="badge bg-primary-subtle text-primary fw-bold font-monospace px-2 py-1"><%= r.getRoomNumber() %></span>
                                                <h5 class="fw-bold text-dark mt-2 mb-1"><%= r.getRoomName() %></h5>
                                                <div class="text-muted small">
                                                    <i class="bi bi-geo-alt me-1"></i><%= r.getBuilding() %>, <%= r.getFloor() %>
                                                </div>
                                            </div>
                                            <span class="badge-status badge-available">
                                                <i class="bi bi-check-circle-fill me-1"></i>Free
                                            </span>
                                        </div>

                                        <div class="my-3 py-2 border-top border-bottom">
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
                                        <a href="<%= bookUrl %>" class="btn btn-primary w-100 fw-semibold">
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
                    <h4 class="fw-bold text-dark">Check Real-Time Room Vacancies</h4>
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
