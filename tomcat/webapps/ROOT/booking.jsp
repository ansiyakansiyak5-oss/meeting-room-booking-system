<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List, com.meetingroom.Room, com.meetingroom.Booking" %>
<%
    if (session.getAttribute("user") == null) {
        response.sendRedirect(request.getContextPath() + "/index.jsp?msg=auth_required");
        return;
    }

    @SuppressWarnings("unchecked")
    List<Room> rooms = (List<Room>) request.getAttribute("rooms");
    if (rooms == null) {
        // Redirect to servlet to populate rooms
        String q = request.getQueryString();
        response.sendRedirect(request.getContextPath() + "/bookings" + (q != null ? "?" + q : ""));
        return;
    }

    Booking editBooking = (Booking) request.getAttribute("editBooking");
    boolean isEdit = (editBooking != null);

    String error = request.getParameter("error");
    String success = request.getParameter("success");

    // Pre-fill parameters (from Room Availability or default)
    String preRoomId = request.getParameter("roomId");
    String preDate = request.getParameter("date");
    String preStart = request.getParameter("startTime");
    String preEnd = request.getParameter("endTime");
    String preParticipants = request.getParameter("participants");

    if (isEdit) {
        preRoomId = String.valueOf(editBooking.getRoomId());
        preDate = editBooking.getMeetingDate();
        preStart = editBooking.getStartTime().substring(0, 5);
        preEnd = editBooking.getEndTime().substring(0, 5);
        preParticipants = String.valueOf(editBooking.getParticipants());
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= isEdit ? "Edit Reservation" : "Meeting Room Booking" %> - Meeting Room Booking System</title>
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
        <div class="container py-3">

            <div class="row justify-content-center">
                <div class="col-lg-10 col-xl-9">

                    <!-- Header -->
                    <div class="d-flex justify-content-between align-items-center mb-4 flex-wrap gap-2">
                        <div>
                            <h2 class="fw-bold mb-1 text-dark">
                                <i class="bi <%= isEdit ? "bi-pencil-square text-warning" : "bi-calendar-plus text-primary" %> me-2"></i>
                                <%= isEdit ? "Edit Reservation #" + editBooking.getBookingNumber() : "Reserve a Meeting Room" %>
                            </h2>
                            <p class="text-muted mb-0">Fill in the meeting specifications. Instant conflict detection guarantees zero double-bookings.</p>
                        </div>
                        <a href="<%= request.getContextPath() %>/history" class="btn btn-outline-secondary">
                            <i class="bi bi-arrow-left me-1"></i> View All Bookings
                        </a>
                    </div>

                    <!-- Conflict or Validation Alert -->
                    <% if (error != null && !error.isEmpty()) { %>
                        <div class="alert alert-danger alert-dismissible fade show border-danger shadow-sm" role="alert">
                            <div class="d-flex">
                                <i class="bi bi-exclamation-octagon-fill fs-4 me-3 text-danger"></i>
                                <div>
                                    <h6 class="alert-heading fw-bold mb-1">Reservation Issue Detected</h6>
                                    <div><%= error %></div>
                                </div>
                            </div>
                            <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                        </div>
                    <% } %>

                    <!-- Main Booking Form Card -->
                    <div class="card card-custom border-0 shadow-sm">
                        <div class="card-header-custom bg-white border-bottom">
                            <span class="fw-bold text-dark"><i class="bi bi-file-earmark-text me-2 text-primary"></i>Reservation Details</span>
                        </div>
                        <div class="card-body p-4">
                            <form action="<%= request.getContextPath() %>/bookings" method="post" id="bookingForm">
                                <input type="hidden" name="action" value="<%= isEdit ? "update" : "book" %>">
                                <% if (isEdit) { %>
                                    <input type="hidden" name="bookingId" value="<%= editBooking.getBookingId() %>">
                                <% } %>

                                <!-- Section 1: Room Selection -->
                                <h6 class="text-uppercase text-muted fw-bold small mb-3 border-bottom pb-2">
                                    <i class="bi bi-door-open me-1"></i> Room Selection
                                </h6>
                                <div class="row g-3 mb-4">
                                    <div class="col-md-8">
                                        <label for="roomId" class="form-label fw-semibold">Select Meeting Room *</label>
                                        <select name="roomId" id="roomId" class="form-select form-select-lg" required>
                                            <option value="">-- Choose an available room --</option>
                                            <% for (Room r : rooms) { %>
                                                <option value="<%= r.getRoomId() %>"
                                                        data-capacity="<%= r.getCapacity() %>"
                                                        data-type="<%= r.getRoomType() %>"
                                                        <%= (preRoomId != null && preRoomId.equals(String.valueOf(r.getRoomId()))) ? "selected" : "" %>>
                                                    <%= r.getRoomNumber() %> - <%= r.getRoomName() %> (<%= r.getBuilding() %>, Cap: <%= r.getCapacity() %>)
                                                </option>
                                            <% } %>
                                        </select>
                                        <div id="roomCapacityNotice" class="alert alert-info py-2 px-3 mt-2 small d-none"></div>
                                    </div>
                                    <div class="col-md-4">
                                        <label for="participants" class="form-label fw-semibold">Expected Attendees *</label>
                                        <div class="input-group input-group-lg">
                                            <span class="input-group-text"><i class="bi bi-people"></i></span>
                                            <input type="number" name="participants" id="participants" class="form-control" min="1" max="500" value="<%= preParticipants != null ? preParticipants : "5" %>" required>
                                        </div>
                                        <small class="text-muted">Must be &le; room capacity.</small>
                                    </div>
                                </div>

                                <!-- Section 2: Date & Time Schedule -->
                                <h6 class="text-uppercase text-muted fw-bold small mb-3 border-bottom pb-2">
                                    <i class="bi bi-clock me-1"></i> Date &amp; Time Window
                                </h6>
                                <div class="row g-3 mb-4">
                                    <div class="col-md-4">
                                        <label for="meetingDate" class="form-label fw-semibold">Meeting Date *</label>
                                        <div class="input-group">
                                            <span class="input-group-text"><i class="bi bi-calendar3"></i></span>
                                            <input type="date" name="meetingDate" id="meetingDate" class="form-control" value="<%= preDate != null ? preDate : "" %>" required>
                                        </div>
                                    </div>
                                    <div class="col-md-4">
                                        <label for="startTime" class="form-label fw-semibold">Start Time *</label>
                                        <div class="input-group">
                                            <span class="input-group-text"><i class="bi bi-clock"></i></span>
                                            <input type="time" name="startTime" id="startTime" class="form-control" value="<%= preStart != null ? preStart : "09:00" %>" required>
                                        </div>
                                    </div>
                                    <div class="col-md-4">
                                        <label for="endTime" class="form-label fw-semibold">End Time *</label>
                                        <div class="input-group">
                                            <span class="input-group-text"><i class="bi bi-clock-fill"></i></span>
                                            <input type="time" name="endTime" id="endTime" class="form-control" value="<%= preEnd != null ? preEnd : "10:00" %>" required>
                                        </div>
                                    </div>
                                </div>

                                <!-- Section 3: Meeting Information -->
                                <h6 class="text-uppercase text-muted fw-bold small mb-3 border-bottom pb-2">
                                    <i class="bi bi-card-text me-1"></i> Meeting Details
                                </h6>
                                <div class="row g-3 mb-4">
                                    <div class="col-md-12">
                                        <label for="meetingTitle" class="form-label fw-semibold">Meeting Title *</label>
                                        <input type="text" name="meetingTitle" id="meetingTitle" class="form-control" placeholder="e.g. Q4 Strategy Planning & Budget Review" value="<%= isEdit ? editBooking.getMeetingTitle() : "" %>" required>
                                    </div>
                                    <div class="col-md-12">
                                        <label for="purpose" class="form-label fw-semibold">Meeting Agenda / Purpose</label>
                                        <textarea name="purpose" id="purpose" class="form-control" rows="2" placeholder="Brief outline of the meeting agenda, required equipment, or notes..."><%= isEdit && editBooking.getPurpose() != null ? editBooking.getPurpose() : "" %></textarea>
                                    </div>
                                </div>

                                <!-- Section 4: Organizer Information -->
                                <h6 class="text-uppercase text-muted fw-bold small mb-3 border-bottom pb-2">
                                    <i class="bi bi-person-badge me-1"></i> Organizer Information
                                </h6>
                                <div class="row g-3 mb-4">
                                    <div class="col-md-4">
                                        <label for="employeeName" class="form-label fw-semibold">Employee Name *</label>
                                        <input type="text" name="employeeName" id="employeeName" class="form-control" placeholder="e.g. Sarah Connor" value="<%= isEdit ? editBooking.getEmployeeName() : "" %>" required>
                                    </div>
                                    <div class="col-md-4">
                                        <label for="employeeId" class="form-label fw-semibold">Employee ID *</label>
                                        <input type="text" name="employeeId" id="employeeId" class="form-control" placeholder="e.g. EMP-1042" value="<%= isEdit ? editBooking.getEmployeeId() : "" %>" required>
                                    </div>
                                    <div class="col-md-4">
                                        <label for="department" class="form-label fw-semibold">Department</label>
                                        <input type="text" name="department" id="department" class="form-control" placeholder="e.g. Engineering / HR" value="<%= isEdit && editBooking.getDepartment() != null ? editBooking.getDepartment() : "" %>">
                                    </div>
                                    <% if (isEdit) { %>
                                        <div class="col-md-6">
                                            <label for="bookingStatus" class="form-label fw-semibold">Reservation Status</label>
                                            <select name="bookingStatus" id="bookingStatus" class="form-select">
                                                <option value="Booked" <%= "Booked".equals(editBooking.getBookingStatus()) ? "selected" : "" %>>Booked</option>
                                                <option value="Completed" <%= "Completed".equals(editBooking.getBookingStatus()) ? "selected" : "" %>>Completed</option>
                                                <option value="Cancelled" <%= "Cancelled".equals(editBooking.getBookingStatus()) ? "selected" : "" %>>Cancelled</option>
                                            </select>
                                        </div>
                                    <% } %>
                                </div>

                                <!-- Actions -->
                                <div class="d-flex justify-content-end gap-2 pt-3 border-top">
                                    <a href="<%= request.getContextPath() %>/history" class="btn btn-light border px-4">Cancel</a>
                                    <button type="submit" class="btn btn-primary px-5 fw-semibold shadow-sm">
                                        <i class="bi <%= isEdit ? "bi-save" : "bi-check2-circle" %> me-1"></i>
                                        <%= isEdit ? "Save Changes" : "Confirm Booking" %>
                                    </button>
                                </div>
                            </form>
                        </div>
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
