import sys
import serial
import time
import threading
import csv
from PyQt5.QtWidgets import QApplication, QWidget, QVBoxLayout, QHBoxLayout, QPushButton, QLabel, QTextEdit, QGridLayout, QFileDialog
from PyQt5.QtGui import QFont 
from PyQt5.QtCore import QTimer, pyqtSignal, QObject
import pyqtgraph as pg
from datetime import datetime

# Signal class to safely send data from thread to GUI
class SerialListener(QObject):
    data_received = pyqtSignal(str)

# Serial setup (modify 'COM4' to your port)
try:
    ser = serial.Serial('COM4', 115200, timeout=1)
    print("Connected to COM4 at 115200 baud rate")
except serial.SerialException as e:
    print(f"Error opening serial port: {e}")
    ser = None

# Function to listen for incoming data
def listen_for_data(serial_listener):
    if ser:
        while True:
            try:
                if ser.in_waiting > 0:
                    received_data = ser.readline().decode('utf-8').strip()
                    print(f"DEBUG: Raw data received -> {received_data}")
                    if received_data:
                        serial_listener.data_received.emit(received_data)
            except serial.SerialException as e:
                print(f"Error reading from serial port: {e}")
                break

class DroneControlGUI(QWidget):
    def __init__(self):
        super().__init__()
        self.initUI()

        # Serial listener
        self.serial_listener = SerialListener()
        self.serial_listener.data_received.connect(self.handle_cdc_data)

        # Timer to update the graphs every second
        self.graph_update_timer = QTimer()
        self.graph_update_timer.timeout.connect(self.update_graphs)
        self.graph_update_timer.start(50)

        # Initialize data arrays
        self.target_speed_data = []
        self.current_speed_data = []
        self.target_pitch_data = []
        self.current_pitch_1_data = []
        self.current_pitch_2_data = []
        self.loadcell_data = [[] for _ in range(4)]  # Four load cell data arrays
        self.timestamps = []  # To track timestamps

        # Track the last known values
        self.last_speed = 0.0
        self.last_pitch_1 = 0.0
        self.last_pitch_2 = 0.0
        self.last_weights = [0.0] * 4

    def initUI(self):
        # Window settings
        self.setWindowTitle('Drone Control GUI')
        self.setGeometry(100, 100, 1000, 800)

        # CDC log area
        self.cdc_log = QTextEdit(self)
        self.cdc_log.setReadOnly(True)
        self.cdc_log.setFont(QFont('Arial', 10))

        # Labels for speed and pitch
        self.current_speed_label = QLabel('Current Speed: 0')
        self.current_pitch_label = QLabel('Current Pitch 1: 0, Pitch 2: 0')
        self.target_speed_label = QLabel('Target Speed: 0')
        self.target_pitch_label = QLabel('Target Pitch: 0')

        # Graphs for Speed, Pitch, and Load Cells
        self.speed_graph = pg.PlotWidget(self)
        self.speed_graph.setTitle('Speed Graph')
        self.speed_graph.addLegend()

        self.pitch_graph = pg.PlotWidget(self)
        self.pitch_graph.setTitle('Pitch Graph')
        self.pitch_graph.addLegend()

        # Load cell graph
        self.loadcell_graph = pg.PlotWidget(self)
        self.loadcell_graph.setTitle('Load Cell Graph')
        self.loadcell_graph.addLegend()

        # Speed and pitch curves
        self.speed_target_curve = self.speed_graph.plot(pen='g', name="Target Speed")
        self.speed_current_curve = self.speed_graph.plot(pen='r', name="Current Speed")

        self.pitch_target_curve = self.pitch_graph.plot(pen='g', name="Target Pitch")
        self.pitch_current_1_curve = self.pitch_graph.plot(pen='r', name="Current Pitch 1")
        self.pitch_current_2_curve = self.pitch_graph.plot(pen='b', name="Current Pitch 2")

        # Load cell curves
        self.loadcell_curves = [self.loadcell_graph.plot(pen=pg.intColor(i), name=f"Load Cell {i+1}") for i in range(4)]

        # Save to CSV button
        self.save_csv_button = QPushButton('Save to CSV', self)
        self.save_csv_button.clicked.connect(self.save_to_csv)

        # Layout
        self.layoutUI()

    def layoutUI(self):
        grid = QGridLayout()

        # Control buttons
        grid.addWidget(self.current_speed_label, 0, 0)
        grid.addWidget(self.current_pitch_label, 0, 1)
        grid.addWidget(self.target_speed_label, 0, 2)
        grid.addWidget(self.target_pitch_label, 0, 3)
        grid.addWidget(self.save_csv_button, 0, 4)

        # Graphs for speed, pitch, and load cells
        grid.addWidget(self.speed_graph, 1, 0, 1, 5)
        grid.addWidget(self.pitch_graph, 2, 0, 1, 5)
        grid.addWidget(self.loadcell_graph, 3, 0, 1, 5)  # Load cell graph

        # CDC Log
        grid.addWidget(QLabel('CDC Log:'), 4, 0)
        grid.addWidget(self.cdc_log, 5, 0, 1, 5)

        self.setLayout(grid)

    def handle_cdc_data(self, message):
        self.cdc_log.append(f"Received: {message}")
        print(f"DEBUG: CDC Data received -> {message}")

        current_time = datetime.now().strftime('%Y-%m-%d %H:%M:%S')

        if message.startswith("&_DATA"):
            try:
                clean_message = message[7:-1]
                parts = clean_message.split('_')

                if len(parts) >= 5:
                    current_speed = float(parts[0])
                    target_speed= float(parts[1])
                    target_pitch = float(parts[2])
                    current_pitch_1 = float(parts[3])
                    current_pitch_2 = float(parts[4])

                    # Update the last known values
                    self.last_speed = current_speed
                    self.last_pitch_1 = current_pitch_1
                    self.last_pitch_2 = current_pitch_2

                    # Append the data and timestamps
                    self.target_speed_data.append(target_speed)
                    self.current_speed_data.append(current_speed)
                    self.target_pitch_data.append(target_pitch)
                    self.current_pitch_1_data.append(current_pitch_1)
                    self.current_pitch_2_data.append(current_pitch_2)
                    self.timestamps.append(current_time)

                    self.current_speed_label.setText(f'Current Speed: {current_speed:.2f}')
                    self.current_pitch_label.setText(f'Current Pitch 1: {current_pitch_1:.2f}, Pitch 2: {current_pitch_2:.2f}')
                    self.target_speed_label.setText(f'Target Speed: {target_speed:.2f}')
                    self.target_pitch_label.setText(f'Target Pitch: {target_pitch:.2f}')

                    print(f"DEBUG: Parsed Data -> Target Speed: {target_speed}, Current Speed: {current_speed}, "
                          f"Target Pitch: {target_pitch}, Current Pitch 1: {current_pitch_1}, Current Pitch 2: {current_pitch_2}")
                else:
                    print("ERROR: Insufficient data received")
            except (IndexError, ValueError) as e:
                print(f"Error parsing CDC data: {e}")

        elif message.startswith("&_WGT"):
            try:
                clean_message = message[6:-1]  # Remove '&_WGT_' prefix and '*' suffix
                # Split the message and convert to float, preserving negative signs
                parts = [float(x) for x in clean_message.split('_') if x]
                if len(parts) >= 4:
                    # Update load cell data and maintain last weights
                    for i in range(4):
                        if i < len(parts):
                            self.loadcell_data[i].append(parts[i])
                            self.last_weights[i] = parts[i]  # Update last known weight
                        else:
                            # Append the last known weight if no new data received
                            self.loadcell_data[i].append(self.last_weights[i])

                    print(f"DEBUG: Parsed Load Cell Data -> {self.loadcell_data[0][-1]}, {self.loadcell_data[1][-1]}, "
                          f"{self.loadcell_data[2][-1]}, {self.loadcell_data[3][-1]}")
                else:
                    print("ERROR: Insufficient load cell data received")
            except (IndexError, ValueError) as e:
                print(f"Error parsing Load Cell data: {e}")

    def update_graphs(self):
        self.speed_target_curve.setData(self.target_speed_data)
        self.speed_current_curve.setData(self.current_speed_data)

        self.pitch_target_curve.setData(self.target_pitch_data)
        self.pitch_current_1_curve.setData(self.current_pitch_1_data)
        self.pitch_current_2_curve.setData(self.current_pitch_2_data)

        for i in range(4):
            self.loadcell_curves[i].setData(self.loadcell_data[i])

    def save_to_csv(self):
        options = QFileDialog.Options()
        filename, _ = QFileDialog.getSaveFileName(self, "Save Data", "", "CSV Files (*.csv)", options=options)
        if filename:
            with open(filename, mode='w', newline='') as csv_file:
                writer = csv.writer(csv_file)
                # Write header
                writer.writerow(['Timestamp', 'Target Speed', 'Current Speed', 'Target Pitch', 'Current Pitch 1', 'Current Pitch 2', 
                                 'Load Cell 1', 'Load Cell 2', 'Load Cell 3', 'Load Cell 4'])
                # Write data rows
                for i in range(len(self.target_speed_data)):
                    # Use the timestamp corresponding to the current index
                    timestamp = self.timestamps[i] if i < len(self.timestamps) else ''
                    writer.writerow([
                        timestamp,
                        self.target_speed_data[i] if i < len(self.target_speed_data) else '',
                        self.current_speed_data[i] if i < len(self.current_speed_data) else '',
                        self.target_pitch_data[i] if i < len(self.target_pitch_data) else '',
                        self.current_pitch_1_data[i] if i < len(self.current_pitch_1_data) else '',
                        self.current_pitch_2_data[i] if i < len(self.current_pitch_2_data) else '',
                        self.loadcell_data[0][i] if i < len(self.loadcell_data[0]) else '',
                        self.loadcell_data[1][i] if i < len(self.loadcell_data[1]) else '',
                        self.loadcell_data[2][i] if i < len(self.loadcell_data[2]) else '',
                        self.loadcell_data[3][i] if i < len(self.loadcell_data[3]) else '',
                    ])
            print(f"Data saved to {filename}")

def main():
    app = QApplication(sys.argv)
    gui = DroneControlGUI()

    # Start the serial listener in a separate thread
    listener_thread = threading.Thread(target=listen_for_data, args=(gui.serial_listener,))
    listener_thread.daemon = True
    listener_thread.start()

    gui.show()
    sys.exit(app.exec_())

if __name__ == '__main__':
    main()
