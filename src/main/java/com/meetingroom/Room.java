package com.meetingroom;

import java.io.Serializable;

public class Room implements Serializable {
    private static final long serialVersionUID = 1L;

    private int roomId;
    private String roomNumber;
    private String roomName;
    private String building;
    private String floor;
    private int capacity;
    private String roomType;
    private String facilities;
    private double hourlyRate;
    private String status;

    public Room() {
        this.hourlyRate = 15.00;
        this.status = "Available";
    }

    public Room(int roomId, String roomNumber, String roomName, String building, String floor,
                int capacity, String roomType, String facilities, double hourlyRate, String status) {
        this.roomId = roomId;
        this.roomNumber = roomNumber;
        this.roomName = roomName;
        this.building = building;
        this.floor = floor;
        this.capacity = capacity;
        this.roomType = roomType;
        this.facilities = facilities;
        this.hourlyRate = hourlyRate;
        this.status = status;
    }

    public Room(int roomId, String roomNumber, String roomName, String building, String floor,
                int capacity, String roomType, String facilities, String status) {
        this(roomId, roomNumber, roomName, building, floor, capacity, roomType, facilities, 15.00, status);
    }

    public int getRoomId() { return roomId; }
    public void setRoomId(int roomId) { this.roomId = roomId; }

    public String getRoomNumber() { return roomNumber; }
    public void setRoomNumber(String roomNumber) { this.roomNumber = roomNumber; }

    public String getRoomName() { return roomName; }
    public void setRoomName(String roomName) { this.roomName = roomName; }

    public String getBuilding() { return building; }
    public void setBuilding(String building) { this.building = building; }

    public String getFloor() { return floor; }
    public void setFloor(String floor) { this.floor = floor; }

    public int getCapacity() { return capacity; }
    public void setCapacity(int capacity) { this.capacity = capacity; }

    public String getRoomType() { return roomType; }
    public void setRoomType(String roomType) { this.roomType = roomType; }

    public String getFacilities() { return facilities; }
    public void setFacilities(String facilities) { this.facilities = facilities; }

    public double getHourlyRate() { return hourlyRate; }
    public void setHourlyRate(double hourlyRate) { this.hourlyRate = hourlyRate; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
}
