<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List, com.meetingroom.Room" %>
<%
    if (session.getAttribute("user") == null) {
        response.sendRedirect(request.getContextPath() + "/index.jsp?msg=auth_required");
        return;
    }

    @SuppressWarnings("unchecked")
    List<Room> rooms = (List<Room>) request.getAttribute("rooms");
    if (rooms == null) {
        response.sendRedirect(request.getContextPath() + "/rooms");
        return;
    }

    String error = request.getParameter("error");
    String success = request.getParameter("success");
    String dbError = (String) request.getAttribute("dbError");
    String searchQuery = (String) request.getAttribute("searchQuery");
    if (searchQuery == null) searchQuery = "";
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Room Management - MeetRoom Pro</title>
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

            <!-- Title & Actions -->
            <div class="d-flex justify-content-between align-items-center mb-4 flex-wrap gap-2">
                <div>
                    <h2 class="fw-bold mb-1"><i class="bi bi-door-open text-primary me-2"></i>Room Management</h2>
                    <p class="text-muted mb-0">Manage meeting rooms, equipment, capacity, and hourly billing rates.</p>
                </div>
                <button type="button" class="btn btn-primary shadow-sm" data-bs-toggle="modal" data-bs-target="#addRoomModal">
                    <i class="bi bi-plus-circle me-1"></i> Add New Room
                </button>
            </div>

            <!-- Feedback Alerts -->
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

            <!-- Search and Filter Bar -->
            <div class="card card-custom mb-4 p-3 border-0">
                <form action="<%= request.getContextPath() %>/rooms" method="get" class="row g-2 align-items-center">
                    <div class="col-md-8 col-sm-12">
                        <div class="input-group">
                            <span class="input-group-text"><i class="bi bi-search text-muted"></i></span>
                            <input type="text" name="search" class="form-control" placeholder="Search by Room Number, Name, Building, Type..." value="<%= searchQuery %>">
                        </div>
                    </div>
                    <div class="col-md-2 col-sm-6">
                        <button type="submit" class="btn btn-outline-primary w-100">
                            <i class="bi bi-funnel me-1"></i> Filter
                        </button>
                    </div>
                    <div class="col-md-2 col-sm-6">
                        <a href="<%= request.getContextPath() %>/rooms" class="btn btn-outline-secondary w-100">
                            <i class="bi bi-arrow-counterclockwise me-1"></i> Reset
                        </a>
                    </div>
                </form>
            </div>

            <!-- Room Table -->
            <div class="card card-custom border-0 overflow-hidden mb-4">
                <div class="card-header-custom d-flex justify-content-between align-items-center">
                    <span class="fw-bold">Registered Rooms (<%= rooms.size() %>)</span>
                    <span class="badge bg-secondary bg-opacity-10 text-secondary border">Safe deletion enabled</span>
                </div>
                <div class="card-body p-0">
                    <div class="table-responsive">
                        <table class="table table-custom table-hover align-middle mb-0">
                            <thead>
                                <tr>
                                    <th>Room #</th>
                                    <th>Room Name</th>
                                    <th>Building &amp; Floor</th>
                                    <th>Capacity</th>
                                    <th>Type</th>
                                    <th>Hourly Rate</th>
                                    <th>Facilities</th>
                                    <th>Status</th>
                                    <th class="text-end">Actions</th>
                                </tr>
                            </thead>
                            <tbody>
                                <% if (rooms.isEmpty()) { %>
                                    <tr>
                                        <td colspan="9" class="text-center py-5 text-muted">
                                            <i class="bi bi-door-closed fs-1 d-block mb-2 text-secondary"></i>
                                            No rooms found matching your search.
                                        </td>
                                    </tr>
                                <% } else { %>
                                    <% for (Room r : rooms) { %>
                                        <tr>
                                            <td class="fw-bold font-monospace text-primary"><%= r.getRoomNumber() %></td>
                                            <td>
                                                <div class="fw-semibold"><%= r.getRoomName() %></div>
                                            </td>
                                            <td>
                                                <div><%= r.getBuilding() %></div>
                                                <small class="text-muted"><%= r.getFloor() %></small>
                                            </td>
                                            <td>
                                                <span class="badge bg-secondary bg-opacity-25 border">
                                                    <i class="bi bi-people me-1"></i><%= r.getCapacity() %> Seats
                                                </span>
                                            </td>
                                            <td><span class="badge bg-info bg-opacity-25 text-info border border-info border-opacity-25"><%= r.getRoomType() %></span></td>
                                            <td>
                                                <span class="fw-bold text-success">$<%= String.format("%.2f", r.getHourlyRate()) %></span>
                                                <small class="text-muted">/hr</small>
                                            </td>
                                            <td class="small text-muted" style="max-width: 250px;">
                                                <%= (r.getFacilities() != null && !r.getFacilities().isEmpty()) ? r.getFacilities() : "Standard equipment" %>
                                            </td>
                                            <td>
                                                <% if ("Available".equalsIgnoreCase(r.getStatus())) { %>
                                                    <span class="badge-status badge-available">
                                                        <i class="bi bi-check-circle-fill me-1"></i>Available
                                                    </span>
                                                <% } else { %>
                                                    <span class="badge-status badge-maintenance">
                                                        <i class="bi bi-tools me-1"></i><%= r.getStatus() %>
                                                    </span>
                                                <% } %>
                                            </td>
                                            <td class="text-end">
                                                <div class="btn-group btn-group-sm">
                                                    <button type="button" class="btn btn-outline-secondary" title="Edit Room"
                                                            onclick="openEditRoomModal(<%= r.getRoomId() %>, '<%= r.getRoomNumber() %>', '<%= r.getRoomName().replace("'", "\\'") %>', '<%= r.getBuilding().replace("'", "\\'") %>', '<%= r.getFloor().replace("'", "\\'") %>', <%= r.getCapacity() %>, '<%= r.getRoomType() %>', '<%= (r.getFacilities() != null ? r.getFacilities().replace("'", "\\'") : "") %>', <%= r.getHourlyRate() %>, '<%= r.getStatus() %>')">
                                                        <i class="bi bi-pencil"></i>
                                                    </button>
                                                    <a href="<%= request.getContextPath() %>/rooms?action=toggle&roomId=<%= r.getRoomId() %>" class="btn btn-outline-warning" title="Toggle Available / Maintenance">
                                                        <i class="bi bi-power"></i>
                                                    </a>
                                                    <a href="<%= request.getContextPath() %>/rooms?action=delete&roomId=<%= r.getRoomId() %>" class="btn btn-outline-danger" title="Delete Room"
                                                       onclick="return confirmDeleteRoom('<%= r.getRoomName().replace("'", "\\'") %>');">
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

    <!-- Modal: Add New Room -->
    <div class="modal fade" id="addRoomModal" tabindex="-1" aria-labelledby="addRoomModalLabel" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered">
            <div class="modal-content border-0 shadow">
                <form action="<%= request.getContextPath() %>/rooms" method="post">
                    <input type="hidden" name="action" value="add">
                    <div class="modal-header bg-primary text-white">
                        <h5 class="modal-title fw-bold" id="addRoomModalLabel"><i class="bi bi-plus-circle me-2"></i>Add New Room</h5>
                        <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                    </div>
                    <div class="modal-body p-4">
                        <div class="row g-3">
                            <div class="col-md-6">
                                <label class="form-label fw-semibold">Room Number *</label>
                                <input type="text" name="roomNumber" class="form-control" placeholder="e.g. CR-101" required>
                            </div>
                            <div class="col-md-6">
                                <label class="form-label fw-semibold">Capacity (People) *</label>
                                <input type="number" name="capacity" class="form-control" min="1" max="500" placeholder="e.g. 15" required>
                            </div>
                            <div class="col-12">
                                <label class="form-label fw-semibold">Room Name *</label>
                                <input type="text" name="roomName" class="form-control" placeholder="e.g. Executive Boardroom" required>
                            </div>
                            <div class="col-md-6">
                                <label class="form-label fw-semibold">Hourly Rate ($/hr) *</label>
                                <div class="input-group">
                                    <span class="input-group-text">$</span>
                                    <input type="number" step="0.5" name="hourlyRate" class="form-control" value="15.00" required>
                                </div>
                            </div>
                            <div class="col-md-6">
                                <label class="form-label fw-semibold">Building</label>
                                <input type="text" name="building" class="form-control" placeholder="e.g. Academic Block B">
                            </div>
                            <div class="col-md-6">
                                <label class="form-label fw-semibold">Floor</label>
                                <input type="text" name="floor" class="form-control" placeholder="e.g. 2nd Floor">
                            </div>
                            <div class="col-md-6">
                                <label class="form-label fw-semibold">Room Type</label>
                                <select name="roomType" class="form-select">
                                    <option value="Meeting Room">Meeting Room</option>
                                    <option value="Conference Room">Conference Room</option>
                                    <option value="Board Room">Board Room</option>
                                    <option value="Huddle Room">Huddle Room</option>
                                    <option value="Seminar Room">Seminar Room</option>
                                    <option value="Student Project Lab">Student Project Lab</option>
                                </select>
                            </div>
                            <div class="col-md-12">
                                <label class="form-label fw-semibold">Status</label>
                                <select name="status" class="form-select">
                                    <option value="Available">Available</option>
                                    <option value="Maintenance">Maintenance</option>
                                </select>
                            </div>
                            <div class="col-12">
                                <label class="form-label fw-semibold">Facilities / Equipment</label>
                                <textarea name="facilities" class="form-control" rows="2" placeholder="e.g. 4K Projector, High-speed Wi-Fi, Video Bar, AC, Power Plugs"></textarea>
                            </div>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                        <button type="submit" class="btn btn-primary"><i class="bi bi-check2-circle me-1"></i> Save Room</button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <!-- Modal: Edit Room -->
    <div class="modal fade" id="editRoomModal" tabindex="-1" aria-labelledby="editRoomModalLabel" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered">
            <div class="modal-content border-0 shadow">
                <form action="<%= request.getContextPath() %>/rooms" method="post">
                    <input type="hidden" name="action" value="update">
                    <input type="hidden" name="roomId" id="editRoomId">
                    <div class="modal-header bg-dark text-white">
                        <h5 class="modal-title fw-bold" id="editRoomModalLabel"><i class="bi bi-pencil me-2"></i>Edit Room</h5>
                        <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                    </div>
                    <div class="modal-body p-4">
                        <div class="row g-3">
                            <div class="col-md-6">
                                <label class="form-label fw-semibold">Room Number *</label>
                                <input type="text" name="roomNumber" id="editRoomNumber" class="form-control" required>
                            </div>
                            <div class="col-md-6">
                                <label class="form-label fw-semibold">Capacity (People) *</label>
                                <input type="number" name="capacity" id="editCapacity" class="form-control" min="1" max="500" required>
                            </div>
                            <div class="col-12">
                                <label class="form-label fw-semibold">Room Name *</label>
                                <input type="text" name="roomName" id="editRoomName" class="form-control" required>
                            </div>
                            <div class="col-md-6">
                                <label class="form-label fw-semibold">Hourly Rate ($/hr) *</label>
                                <div class="input-group">
                                    <span class="input-group-text">$</span>
                                    <input type="number" step="0.5" name="hourlyRate" id="editHourlyRate" class="form-control" required>
                                </div>
                            </div>
                            <div class="col-md-6">
                                <label class="form-label fw-semibold">Building</label>
                                <input type="text" name="building" id="editBuilding" class="form-control">
                            </div>
                            <div class="col-md-6">
                                <label class="form-label fw-semibold">Floor</label>
                                <input type="text" name="floor" id="editFloor" class="form-control">
                            </div>
                            <div class="col-md-6">
                                <label class="form-label fw-semibold">Room Type</label>
                                <select name="roomType" id="editRoomType" class="form-select">
                                    <option value="Meeting Room">Meeting Room</option>
                                    <option value="Conference Room">Conference Room</option>
                                    <option value="Board Room">Board Room</option>
                                    <option value="Huddle Room">Huddle Room</option>
                                    <option value="Seminar Room">Seminar Room</option>
                                    <option value="Student Project Lab">Student Project Lab</option>
                                </select>
                            </div>
                            <div class="col-md-12">
                                <label class="form-label fw-semibold">Status</label>
                                <select name="status" id="editStatus" class="form-select">
                                    <option value="Available">Available</option>
                                    <option value="Maintenance">Maintenance</option>
                                </select>
                            </div>
                            <div class="col-12">
                                <label class="form-label fw-semibold">Facilities / Equipment</label>
                                <textarea name="facilities" id="editFacilities" class="form-control" rows="2"></textarea>
                            </div>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                        <button type="submit" class="btn btn-primary"><i class="bi bi-save me-1"></i> Update Room</button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <!-- Bootstrap 5 JS Bundle -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <script src="<%= request.getContextPath() %>/js/script.js"></script>
</body>
</html>
