<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List, com.meetingroom.Booking" %>
<%
    if (session.getAttribute("user") == null) {
        response.sendRedirect(request.getContextPath() + "/index.jsp?msg=auth_required");
        return;
    }

    @SuppressWarnings("unchecked")
    List<Booking> bookings = (List<Booking>) request.getAttribute("bookings");
    if (bookings == null) {
        // Redirect to servlet to populate
        String q = request.getQueryString();
        response.sendRedirect(request.getContextPath() + "/history" + (q != null ? "?" + q : ""));
        return;
    }

    String error = request.getParameter("error");
    String success = request.getParameter("success");
    String dbError = (String) request.getAttribute("dbError");
    String searchQuery = (String) request.getAttribute("searchQuery");
    String statusFilter = (String) request.getAttribute("statusFilter");
    String dateFilter = (String) request.getAttribute("dateFilter");

    if (searchQuery == null) searchQuery = "";
    if (statusFilter == null) statusFilter = "ALL";
    if (dateFilter == null) dateFilter = "";
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Booking History - Meeting Room Booking System</title>
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
            <div class="d-flex justify-content-between align-items-center mb-3 flex-wrap gap-2">
                <div>
                    <h2 class="fw-bold mb-1 text-dark"><i class="bi bi-clock-history text-primary me-2"></i>Booking History</h2>
                    <p class="text-muted mb-0">Track, update, print confirmation receipts, or cancel meeting room reservations.</p>
                </div>
                <a href="<%= request.getContextPath() %>/bookings" class="btn btn-primary">
                    <i class="bi bi-calendar-plus me-1"></i> New Reservation
                </a>
            </div>

            <!-- Alerts -->
            <% if (error != null && !error.isEmpty()) { %>
                <div class="alert alert-danger alert-dismissible fade show" role="alert">
                    <i class="bi bi-exclamation-triangle-fill me-2"></i><%= error %>
                    <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                </div>
            <% } %>

            <% if (dbError != null && !dbError.isEmpty()) { %>
                <div class="alert alert-danger alert-dismissible fade show" role="alert">
                    <i class="bi bi-exclamation-triangle-fill me-2"></i><%= dbError %>
                    <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                </div>
            <% } %>

            <% if (success != null && !success.isEmpty()) { %>
                <div class="alert alert-success alert-dismissible fade show" role="alert">
                    <i class="bi bi-check-circle-fill me-2"></i><%= success %>
                    <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                </div>
            <% } %>

            <!-- Filter Card -->
            <div class="card card-custom mb-4 p-3 border-0">
                <form action="<%= request.getContextPath() %>/history" method="get" class="row g-2 align-items-center">
                    <div class="col-md-5 col-sm-12">
                        <div class="input-group">
                            <span class="input-group-text bg-white"><i class="bi bi-search text-muted"></i></span>
                            <input type="text" name="search" class="form-control" placeholder="Search by Ref #, Title, Organizer, Room..." value="<%= searchQuery %>">
                        </div>
                    </div>
                    <div class="col-md-3 col-sm-6">
                        <input type="date" name="date" class="form-control" value="<%= dateFilter %>" title="Filter by date">
                    </div>
                    <div class="col-md-2 col-sm-6">
                        <select name="status" class="form-select">
                            <option value="ALL" <%= "ALL".equalsIgnoreCase(statusFilter) ? "selected" : "" %>>All Statuses</option>
                            <option value="Booked" <%= "Booked".equalsIgnoreCase(statusFilter) ? "selected" : "" %>>Booked</option>
                            <option value="Completed" <%= "Completed".equalsIgnoreCase(statusFilter) ? "selected" : "" %>>Completed</option>
                            <option value="Cancelled" <%= "Cancelled".equalsIgnoreCase(statusFilter) ? "selected" : "" %>>Cancelled</option>
                        </select>
                    </div>
                    <div class="col-md-2 col-sm-12 d-flex gap-2">
                        <button type="submit" class="btn btn-outline-primary flex-fill">
                            <i class="bi bi-funnel me-1"></i> Filter
                        </button>
                        <a href="<%= request.getContextPath() %>/history" class="btn btn-outline-secondary" title="Reset Filters">
                            <i class="bi bi-arrow-counterclockwise"></i>
                        </a>
                    </div>
                </form>
            </div>

            <!-- Booking History Table -->
            <div class="card card-custom border-0 overflow-hidden shadow-sm">
                <div class="card-header-custom d-flex justify-content-between align-items-center">
                    <span class="fw-bold text-dark">Bookings Records (<%= bookings.size() %>)</span>
                </div>
                <div class="card-body p-0">
                    <div class="table-responsive">
                        <table class="table table-custom table-hover align-middle mb-0">
                            <thead>
                                <tr>
                                    <th>Ref #</th>
                                    <th>Meeting Title</th>
                                    <th>Room</th>
                                    <th>Date</th>
                                    <th>Time Slot</th>
                                    <th>Organizer</th>
                                    <th>Attendees</th>
                                    <th>Status</th>
                                    <th class="text-end">Actions</th>
                                </tr>
                            </thead>
                            <tbody>
                                <% if (bookings.isEmpty()) { %>
                                    <tr>
                                        <td colspan="9" class="text-center py-5 text-muted">
                                            <i class="bi bi-calendar2-x fs-1 d-block mb-2 text-secondary"></i>
                                            No booking records found.
                                        </td>
                                    </tr>
                                <% } else { %>
                                    <% for (Booking b : bookings) { %>
                                        <tr>
                                            <td class="fw-bold font-monospace text-primary">
                                                <a href="<%= request.getContextPath() %>/receipt?bookingId=<%= b.getBookingId() %>" class="text-decoration-none">
                                                    <%= b.getBookingNumber() %>
                                                </a>
                                            </td>
                                            <td>
                                                <div class="fw-semibold text-dark"><%= b.getMeetingTitle() %></div>
                                                <% if (b.getPurpose() != null && !b.getPurpose().isEmpty()) { %>
                                                    <small class="text-muted text-truncate d-inline-block" style="max-width: 200px;"><%= b.getPurpose() %></small>
                                                <% } %>
                                            </td>
                                            <td>
                                                <div><strong><%= b.getRoomNumber() %></strong></div>
                                                <small class="text-muted"><%= b.getRoomName() %></small>
                                            </td>
                                            <td>
                                                <i class="bi bi-calendar3 me-1 text-muted"></i><%= b.getMeetingDate() %>
                                            </td>
                                            <td>
                                                <span class="badge bg-light text-dark border">
                                                    <i class="bi bi-clock me-1 text-muted"></i>
                                                    <%= b.getStartTime().substring(0, 5) %> - <%= b.getEndTime().substring(0, 5) %>
                                                </span>
                                            </td>
                                            <td>
                                                <div><%= b.getEmployeeName() %></div>
                                                <small class="text-muted"><%= b.getDepartment() != null ? b.getDepartment() : "" %> (<%= b.getEmployeeId() %>)</small>
                                            </td>
                                            <td>
                                                <span class="badge bg-light text-secondary border">
                                                    <i class="bi bi-people me-1"></i><%= b.getParticipants() %>
                                                </span>
                                            </td>
                                            <td>
                                                <% if ("Booked".equalsIgnoreCase(b.getBookingStatus())) { %>
                                                    <span class="badge-status badge-booked">
                                                        <i class="bi bi-check-circle-fill me-1"></i>Booked
                                                    </span>
                                                <% } else if ("Cancelled".equalsIgnoreCase(b.getBookingStatus())) { %>
                                                    <span class="badge-status badge-cancelled">
                                                        <i class="bi bi-x-circle-fill me-1"></i>Cancelled
                                                    </span>
                                                <% } else { %>
                                                    <span class="badge-status badge-completed">
                                                        <%= b.getBookingStatus() %>
                                                    </span>
                                                <% } %>
                                            </td>
                                            <td class="text-end">
                                                <div class="btn-group btn-group-sm">
                                                    <a href="<%= request.getContextPath() %>/receipt?bookingId=<%= b.getBookingId() %>" class="btn btn-outline-primary" title="Receipt / Slip">
                                                        <i class="bi bi-receipt"></i>
                                                    </a>
                                                    <% if ("Booked".equalsIgnoreCase(b.getBookingStatus())) { %>
                                                        <a href="<%= request.getContextPath() %>/bookings?editId=<%= b.getBookingId() %>" class="btn btn-outline-secondary" title="Edit Booking">
                                                            <i class="bi bi-pencil"></i>
                                                        </a>
                                                        <a href="<%= request.getContextPath() %>/bookings?action=cancel&bookingId=<%= b.getBookingId() %>" class="btn btn-outline-warning" title="Cancel Booking"
                                                           onclick="return confirmCancelBooking('<%= b.getBookingNumber() %>');">
                                                            <i class="bi bi-x-octagon"></i>
                                                        </a>
                                                    <% } %>
                                                    <a href="<%= request.getContextPath() %>/bookings?action=delete&bookingId=<%= b.getBookingId() %>" class="btn btn-outline-danger" title="Delete Record"
                                                       onclick="return confirmDeleteBooking('<%= b.getBookingNumber() %>');">
                                                        <i class="bi bi-trash"></i>
                                                    </a>
                                                </div>
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
