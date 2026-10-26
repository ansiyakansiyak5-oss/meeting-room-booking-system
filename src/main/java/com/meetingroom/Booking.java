package com.meetingroom;

import java.io.Serializable;

public class Booking implements Serializable {
    private static final long serialVersionUID = 1L;

    private int bookingId;
    private String bookingNumber;
    private int roomId;
    private String roomNumber;
    private String roomName;
    private String employeeName;
    private String employeeId;
    private String department;
    private String userType;    // 'Student', 'Employee', 'Faculty', 'Student Club'
    private String meetingTitle;
    private String meetingDate; // YYYY-MM-DD
    private String startTime;   // HH:MM
    private String endTime;     // HH:MM
    private int participants;
    private String purpose;
    private double totalAmount;
    private String paymentMethod; // 'Online - UPI / Card', 'Offline - Pay at Desk'
    private String paymentStatus; // 'Paid', 'Pending'
    private String bookingStatus; // 'Booked', 'Cancelled', 'Completed'

    public Booking() {
        this.userType = "Employee";
        this.paymentMethod = "Offline";
        this.paymentStatus = "Pending";
        this.bookingStatus = "Booked";
    }

    public Booking(int bookingId, String bookingNumber, int roomId, String roomNumber, String roomName,
                   String employeeName, String employeeId, String department, String userType, String meetingTitle,
                   String meetingDate, String startTime, String endTime, int participants,
                   String purpose, double totalAmount, String paymentMethod, String paymentStatus, String bookingStatus) {
        this.bookingId = bookingId;
        this.bookingNumber = bookingNumber;
        this.roomId = roomId;
        this.roomNumber = roomNumber;
        this.roomName = roomName;
        this.employeeName = employeeName;
        this.employeeId = employeeId;
        this.department = department;
        this.userType = (userType != null && !userType.isEmpty()) ? userType : "Employee";
        this.meetingTitle = meetingTitle;
        this.meetingDate = meetingDate;
        this.startTime = startTime;
        this.endTime = endTime;
        this.participants = participants;
        this.purpose = purpose;
        this.totalAmount = totalAmount;
        this.paymentMethod = (paymentMethod != null && !paymentMethod.isEmpty()) ? paymentMethod : "Offline";
        this.paymentStatus = (paymentStatus != null && !paymentStatus.isEmpty()) ? paymentStatus : "Pending";
        this.bookingStatus = bookingStatus;
    }

    // Overload for backward compatibility
    public Booking(int bookingId, String bookingNumber, int roomId, String roomNumber, String roomName,
                   String employeeName, String employeeId, String department, String meetingTitle,
                   String meetingDate, String startTime, String endTime, int participants,
                   String purpose, String bookingStatus) {
        this(bookingId, bookingNumber, roomId, roomNumber, roomName, employeeName, employeeId, department,
             "Employee", meetingTitle, meetingDate, startTime, endTime, participants, purpose, 0.00, "Offline", "Pending", bookingStatus);
    }

    public int getBookingId() { return bookingId; }
    public void setBookingId(int bookingId) { this.bookingId = bookingId; }

    public String getBookingNumber() { return bookingNumber; }
    public void setBookingNumber(String bookingNumber) { this.bookingNumber = bookingNumber; }

    public int getRoomId() { return roomId; }
    public void setRoomId(int roomId) { this.roomId = roomId; }

    public String getRoomNumber() { return roomNumber; }
    public void setRoomNumber(String roomNumber) { this.roomNumber = roomNumber; }

    public String getRoomName() { return roomName; }
    public void setRoomName(String roomName) { this.roomName = roomName; }

    public String getEmployeeName() { return employeeName; }
    public void setEmployeeName(String employeeName) { this.employeeName = employeeName; }

    public String getEmployeeId() { return employeeId; }
    public void setEmployeeId(String employeeId) { this.employeeId = employeeId; }

    public String getDepartment() { return department; }
    public void setDepartment(String department) { this.department = department; }

    public String getUserType() { return userType; }
    public void setUserType(String userType) { this.userType = userType; }

    public String getMeetingTitle() { return meetingTitle; }
    public void setMeetingTitle(String meetingTitle) { this.meetingTitle = meetingTitle; }

    public String getMeetingDate() { return meetingDate; }
    public void setMeetingDate(String meetingDate) { this.meetingDate = meetingDate; }

    public String getStartTime() { return startTime; }
    public void setStartTime(String startTime) { this.startTime = startTime; }

    public String getEndTime() { return endTime; }
    public void setEndTime(String endTime) { this.endTime = endTime; }

    public int getParticipants() { return participants; }
    public void setParticipants(int participants) { this.participants = participants; }

    public String getPurpose() { return purpose; }
    public void setPurpose(String purpose) { this.purpose = purpose; }

    public double getTotalAmount() { return totalAmount; }
    public void setTotalAmount(double totalAmount) { this.totalAmount = totalAmount; }

    public String getPaymentMethod() { return paymentMethod; }
    public void setPaymentMethod(String paymentMethod) { this.paymentMethod = paymentMethod; }

    public String getPaymentStatus() { return paymentStatus; }
    public void setPaymentStatus(String paymentStatus) { this.paymentStatus = paymentStatus; }

    public String getBookingStatus() { return bookingStatus; }
    public void setBookingStatus(String bookingStatus) { this.bookingStatus = bookingStatus; }
}
