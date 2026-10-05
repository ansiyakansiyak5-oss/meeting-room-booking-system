<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.meetingroom.Booking, com.meetingroom.Room" %>
<%
    if (session.getAttribute("user") == null) {
        response.sendRedirect(request.getContextPath() + "/index.jsp?msg=auth_required");
        return;
    }

    Booking booking = (Booking) request.getAttribute("booking");
    Room room = (Room) request.getAttribute("room");

    if (booking == null) {
        String bookingId = request.getParameter("bookingId");
        String bookingNumber = request.getParameter("bookingNumber");
        if (bookingId != null || bookingNumber != null) {
            response.sendRedirect(request.getContextPath() + "/receipt?" + request.getQueryString());
            return;
        } else {
            response.sendRedirect(request.getContextPath() + "/history");
            return;
        }
    }

    String isNew = request.getParameter("new");
    String isUpdated = request.getParameter("updated");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Booking Slip - <%= booking.getBookingNumber() %></title>
    <!-- Bootstrap 5 CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <!-- Bootstrap Icons -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
    <!-- Custom CSS -->
    <link href="<%= request.getContextPath() %>/css/style.css" rel="stylesheet">
</head>
<body>

    <!-- Header Navigation (Hidden on Print) -->
    <div class="no-print">
        <%@ include file="navbar.jsp" %>
    </div>

    <div class="main-content py-4">
        <div class="container">

            <!-- Success Notification (Hidden on Print) -->
            <% if ("true".equals(isNew)) { %>
                <div class="alert alert-success alert-dismissible fade show no-print mb-4 shadow-sm" role="alert">
                    <div class="d-flex align-items-center">
                        <i class="bi bi-check-circle-fill fs-3 me-3 text-success"></i>
                        <div>
                            <h5 class="alert-heading fw-bold mb-0">Booking Confirmed Successfully!</h5>
                            <div class="small">Your meeting room has been reserved. You can print or download this receipt below.</div>
                        </div>
                    </div>
                    <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                </div>
            <% } else if ("true".equals(isUpdated)) { %>
                <div class="alert alert-info alert-dismissible fade show no-print mb-4 shadow-sm" role="alert">
                    <div class="d-flex align-items-center">
                        <i class="bi bi-info-circle-fill fs-3 me-3 text-info"></i>
                        <div>
                            <h5 class="alert-heading fw-bold mb-0">Reservation Updated Successfully</h5>
                            <div class="small">Changes to your reservation have been saved.</div>
                        </div>
                    </div>
                    <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                </div>
            <% } %>

            <!-- Receipt Action Toolbar (Hidden on Print) -->
            <div class="d-flex justify-content-between align-items-center mb-4 no-print flex-wrap gap-2">
                <a href="<%= request.getContextPath() %>/history" class="btn btn-outline-secondary">
                    <i class="bi bi-arrow-left me-1"></i> Back to History
                </a>
                <div class="d-flex gap-2">
                    <a href="<%= request.getContextPath() %>/receipt?bookingId=<%= booking.getBookingId() %>&download=txt" class="btn btn-outline-primary">
                        <i class="bi bi-file-earmark-arrow-down me-1"></i> Save as .txt
                    </a>
                    <button type="button" class="btn btn-primary" onclick="window.print();">
                        <i class="bi bi-printer me-1"></i> Print Receipt
                    </button>
                    <a href="<%= request.getContextPath() %>/bookings" class="btn btn-success">
                        <i class="bi bi-plus-lg me-1"></i> New Booking
                    </a>
                </div>
            </div>

            <!-- Receipt Container (Screen & Print Ready) -->
            <div class="receipt-container">

                <!-- Receipt Header -->
                <div class="receipt-header text-center">
                    <div class="d-flex align-items-center justify-content-center mb-2">
                        <i class="bi bi-building-check text-primary fs-2 me-2"></i>
                        <h3 class="fw-bold mb-0 text-dark">MEETING ROOM RESERVATION SLIP</h3>
                    </div>
                    <div class="text-muted small">Corporate Facilities Management &bull; Official Confirmation</div>
                    <div class="mt-3">
                        <span class="receipt-ref-badge fw-bold"><%= booking.getBookingNumber() %></span>
                    </div>
                </div>

                <!-- Status Banner -->
                <div class="d-flex justify-content-between align-items-center bg-light p-3 rounded mb-4 border">
                    <div>
                        <span class="text-muted small text-uppercase fw-semibold d-block">Reservation Status</span>
                        <% if ("Booked".equalsIgnoreCase(booking.getBookingStatus())) { %>
                            <span class="badge-status badge-booked fs-6"><i class="bi bi-check2-circle me-1"></i>Confirmed / Active</span>
                        <% } else if ("Cancelled".equalsIgnoreCase(booking.getBookingStatus())) { %>
                            <span class="badge-status badge-cancelled fs-6"><i class="bi bi-x-circle me-1"></i>Cancelled</span>
                        <% } else { %>
                            <span class="badge-status badge-completed fs-6"><%= booking.getBookingStatus() %></span>
                        <% } %>
                    </div>
                    <div class="text-end">
                        <span class="text-muted small text-uppercase fw-semibold d-block">Reserved On</span>
                        <strong class="text-dark"><%= booking.getMeetingDate() %></strong>
                    </div>
                </div>

                <!-- Section: Meeting Information -->
                <div class="mb-4">
                    <h6 class="text-uppercase text-primary fw-bold border-bottom pb-2 mb-3">
                        <i class="bi bi-calendar-event me-2"></i>Meeting Schedule &amp; Agenda
                    </h6>
                    <div class="row g-3">
                        <div class="col-sm-12">
                            <label class="text-muted small fw-semibold d-block">Meeting Title</label>
                            <h5 class="fw-bold text-dark mb-0"><%= booking.getMeetingTitle() %></h5>
                        </div>
                        <div class="col-sm-4">
                            <label class="text-muted small fw-semibold d-block">Date</label>
                            <div class="fw-semibold text-dark"><i class="bi bi-calendar3 me-1 text-primary"></i><%= booking.getMeetingDate() %></div>
                        </div>
                        <div class="col-sm-4">
                            <label class="text-muted small fw-semibold d-block">Time Slot</label>
                            <div class="fw-semibold text-dark"><i class="bi bi-clock me-1 text-primary"></i><%= booking.getStartTime().substring(0, 5) %> to <%= booking.getEndTime().substring(0, 5) %></div>
                        </div>
                        <div class="col-sm-4">
                            <label class="text-muted small fw-semibold d-block">Participants</label>
                            <div class="fw-semibold text-dark"><i class="bi bi-people me-1 text-primary"></i><%= booking.getParticipants() %> Persons</div>
                        </div>
                        <% if (booking.getPurpose() != null && !booking.getPurpose().isEmpty()) { %>
                            <div class="col-12">
                                <label class="text-muted small fw-semibold d-block">Agenda / Purpose</label>
                                <div class="p-2 bg-light rounded text-secondary border small"><%= booking.getPurpose() %></div>
                            </div>
                        <% } %>
                    </div>
                </div>

                <!-- Section: Room Details -->
                <div class="mb-4">
                    <h6 class="text-uppercase text-primary fw-bold border-bottom pb-2 mb-3">
                        <i class="bi bi-door-closed me-2"></i>Room &amp; Venue Details
                    </h6>
                    <div class="row g-3">
                        <div class="col-sm-6">
                            <label class="text-muted small fw-semibold d-block">Room Name</label>
                            <div class="fw-bold fs-6 text-dark"><%= (room != null) ? room.getRoomName() : booking.getRoomName() %></div>
                        </div>
                        <div class="col-sm-6">
                            <label class="text-muted small fw-semibold d-block">Room Number</label>
                            <div class="font-monospace fw-bold text-dark"><%= (room != null) ? room.getRoomNumber() : booking.getRoomNumber() %></div>
                        </div>
                        <% if (room != null) { %>
                            <div class="col-sm-6">
                                <label class="text-muted small fw-semibold d-block">Location</label>
                                <div><%= room.getBuilding() %>, <%= room.getFloor() %></div>
                            </div>
                            <div class="col-sm-6">
                                <label class="text-muted small fw-semibold d-block">Facility Type &amp; Capacity</label>
                                <div><%= room.getRoomType() %> &bull; <%= room.getCapacity() %> Seats Max</div>
                            </div>
                            <div class="col-12">
                                <label class="text-muted small fw-semibold d-block">Included Amenities</label>
                                <div class="small text-muted"><%= room.getFacilities() %></div>
                            </div>
                        <% } %>
                    </div>
                </div>

                <!-- Section: Booked By -->
                <div class="mb-4">
                    <h6 class="text-uppercase text-primary fw-bold border-bottom pb-2 mb-3">
                        <i class="bi bi-person-check me-2"></i>Organizer Information
                    </h6>
                    <div class="row g-3">
                        <div class="col-sm-4">
                            <label class="text-muted small fw-semibold d-block">Employee Name</label>
                            <div class="fw-semibold text-dark"><%= booking.getEmployeeName() %></div>
                        </div>
                        <div class="col-sm-4">
                            <label class="text-muted small fw-semibold d-block">Employee ID</label>
                            <div class="font-monospace text-dark"><%= booking.getEmployeeId() %></div>
                        </div>
                        <div class="col-sm-4">
                            <label class="text-muted small fw-semibold d-block">Department</label>
                            <div><%= (booking.getDepartment() != null && !booking.getDepartment().isEmpty()) ? booking.getDepartment() : "General" %></div>
                        </div>
                    </div>
                </div>

                <!-- Receipt Footer -->
                <div class="receipt-footer text-center">
                    <p class="text-muted small mb-1">
                        <i class="bi bi-shield-check me-1"></i>Please bring this confirmation receipt when accessing the conference room.
                    </p>
                    <p class="text-muted small mb-0">
                        Generated automatically by MeetRoom Pro &bull; Cloud Database Powered by Aiven MySQL
                    </p>
                </div>

            </div>

        </div>
    </div>

    <!-- Bootstrap 5 JS Bundle -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <script src="<%= request.getContextPath() %>/js/script.js"></script>
</body>
</html>
