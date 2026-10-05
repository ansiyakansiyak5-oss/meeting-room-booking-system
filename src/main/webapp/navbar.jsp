<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    String navbarUsername = (String) session.getAttribute("user");
    String navbarRequestUri = request.getRequestURI();
%>
<nav class="navbar navbar-expand-lg navbar-dark navbar-custom sticky-top">
    <div class="container-fluid px-4">
        <a class="navbar-brand d-flex align-items-center" href="<%= request.getContextPath() %>/dashboard.jsp">
            <i class="bi bi-building-check me-2 text-primary fs-4"></i>
            <span>MeetRoom <span class="badge bg-primary text-white fs-6">Pro</span></span>
        </a>
        <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarMain" aria-controls="navbarMain" aria-expanded="false" aria-label="Toggle navigation">
            <span class="navbar-toggler-icon"></span>
        </button>

        <div class="collapse navbar-collapse" id="navbarMain">
            <ul class="navbar-nav me-auto mb-2 mb-lg-0">
                <li class="nav-item">
                    <a class="nav-link <%= navbarRequestUri.endsWith("dashboard.jsp") ? "active" : "" %>" href="<%= request.getContextPath() %>/dashboard.jsp">
                        <i class="bi bi-speedometer2 me-1"></i> Dashboard
                    </a>
                </li>
                <li class="nav-item">
                    <a class="nav-link <%= navbarRequestUri.contains("rooms") || navbarRequestUri.endsWith("room-management.jsp") ? "active" : "" %>" href="<%= request.getContextPath() %>/rooms">
                        <i class="bi bi-door-open me-1"></i> Room Management
                    </a>
                </li>
                <li class="nav-item">
                    <a class="nav-link <%= navbarRequestUri.contains("bookings") || navbarRequestUri.endsWith("booking.jsp") ? "active" : "" %>" href="<%= request.getContextPath() %>/bookings">
                        <i class="bi bi-calendar-plus me-1"></i> Book a Room
                    </a>
                </li>
                <li class="nav-item">
                    <a class="nav-link <%= navbarRequestUri.contains("availability") || navbarRequestUri.endsWith("availability.jsp") ? "active" : "" %>" href="<%= request.getContextPath() %>/availability">
                        <i class="bi bi-search me-1"></i> Room Availability
                    </a>
                </li>
                <li class="nav-item">
                    <a class="nav-link <%= navbarRequestUri.contains("history") || navbarRequestUri.endsWith("history.jsp") ? "active" : "" %>" href="<%= request.getContextPath() %>/history">
                        <i class="bi bi-clock-history me-1"></i> Booking History
                    </a>
                </li>
            </ul>

            <div class="d-flex align-items-center text-light">
                <% if (navbarUsername != null) { %>
                    <span class="me-3 d-none d-md-inline text-muted small">
                        <i class="bi bi-person-circle me-1 text-primary"></i>
                        Logged in as: <strong class="text-white"><%= navbarUsername %></strong>
                    </span>
                    <a href="<%= request.getContextPath() %>/logout" class="btn btn-outline-danger btn-sm">
                        <i class="bi bi-box-arrow-right me-1"></i> Logout
                    </a>
                <% } else { %>
                    <a href="<%= request.getContextPath() %>/index.jsp" class="btn btn-primary btn-sm">
                        <i class="bi bi-box-arrow-in-right me-1"></i> Login
                    </a>
                <% } %>
            </div>
        </div>
    </div>
</nav>
