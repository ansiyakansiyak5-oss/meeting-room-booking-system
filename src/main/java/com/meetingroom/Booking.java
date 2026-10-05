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
    private String meetingTitle;
    private String meetingDate; // YYYY-MM-DD
    private String startTime;   // HH:MM
    private String endTime;     // HH:MM
    private int participants;
    private String purpose;
    private String bookingStatus; // 'Booked', 'Cancelled', 'Completed'

    public Booking() {}

    public Booking(int bookingId, String bookingNumber, int roomId, String roomNumber, String roomName,
                   String employeeName, String employeeId, String department, String meetingTitle,
                   String meetingDate, String startTime, String endTime, int participants,
                   String purpose, String bookingStatus) {
        this.bookingId = bookingId;
        this.bookingNumber = bookingNumber;
        this.roomId = roomId;
        this.roomNumber = roomNumber;
        this.roomName = roomName;
        this.employeeName = employeeName;
        this.employeeId = employeeId;
        this.department = department;
        this.meetingTitle = meetingTitle;
        this.meetingDate = meetingDate;
        this.startTime = startTime;
        this.endTime = endTime;
        this.participants = participants;
        this.purpose = purpose;
        this.bookingStatus = bookingStatus;
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

    public String getBookingStatus() { return bookingStatus; }
    public void setBookingStatus(String bookingStatus) { this.bookingStatus = bookingStatus; }
}
