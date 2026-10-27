package com.meetingroom;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

@WebServlet(urlPatterns = {"/login", "/logout", "/student-login"})
public class LoginServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String path = request.getServletPath();
        if ("/logout".equals(path)) {
            HttpSession session = request.getSession(false);
            if (session != null) {
                session.invalidate();
            }
            response.sendRedirect(request.getContextPath() + "/index.jsp?msg=logged_out");
        } else {
            response.sendRedirect(request.getContextPath() + "/index.jsp");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String username = request.getParameter("username");
        String password = request.getParameter("password");

        if (username == null || username.trim().isEmpty() || password == null || password.trim().isEmpty()) {
            request.setAttribute("errorMessage", "Username and password cannot be empty.");
            request.getRequestDispatcher("/index.jsp").forward(request, response);
            return;
        }

        username = username.trim();
        password = password.trim();

        String sql = "SELECT user_id, username, password FROM users WHERE username = ?";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, username);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    String storedPassword = rs.getString("password");
                    int userId = rs.getInt("user_id");

                    if (PasswordUtil.verifyPassword(password, storedPassword)) {
                        // If password was stored in legacy plaintext, upgrade to SHA-256 hash
                        if (!PasswordUtil.isHashed(storedPassword)) {
                            try (PreparedStatement updatePs = conn.prepareStatement("UPDATE users SET password = ? WHERE user_id = ?")) {
                                updatePs.setString(1, PasswordUtil.hashPassword(password));
                                updatePs.setInt(2, userId);
                                updatePs.executeUpdate();
                            } catch (Exception updateEx) {
                                System.err.println("[LoginServlet] Note: Could not auto-upgrade password hash: " + updateEx.getMessage());
                            }
                        }

                        // Successful login
                        HttpSession session = request.getSession(true);
                        String loggedInUser = rs.getString("username");
                        session.setAttribute("user", loggedInUser);
                        session.setAttribute("userId", userId);
                        session.setAttribute("role", "admin".equalsIgnoreCase(loggedInUser) ? "Admin" : "Student");

                        response.sendRedirect(request.getContextPath() + "/dashboard.jsp");
                        return;
                    }
                }
                
                // Invalid credentials (either user not found or password incorrect)
                request.setAttribute("errorMessage", "Invalid username or password. Please try again.");
                request.setAttribute("enteredUsername", username);
                request.getRequestDispatcher("/index.jsp").forward(request, response);
            }
        } catch (SQLException e) {
            System.err.println("[LoginServlet] Database authentication error: " + e.getMessage());
            e.printStackTrace();
            request.setAttribute("errorMessage", "Database connection failed. Please ensure the MySQL database server is running and accessible.");
            request.setAttribute("enteredUsername", username);
            request.getRequestDispatcher("/index.jsp").forward(request, response);
        }
    }
}
