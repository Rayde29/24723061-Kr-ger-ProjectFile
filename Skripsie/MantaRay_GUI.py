import sys
import serial
import time
import threading
from PyQt5.QtWidgets import QApplication, QWidget, QVBoxLayout, QHBoxLayout, QPushButton, QLabel, QLineEdit, QTextEdit, QGridLayout, QSlider, QMessageBox
from PyQt5.QtGui import QFont
from PyQt5.QtCore import QTimer, pyqtSignal, QObject, Qt
import pyqtgraph as pg
import os
import csv
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
                    if received_data:
                        serial_listener.data_received.emit(received_data)
            except serial.SerialException as e:
                print(f"Error reading from serial port: {e}")
                break

class DataLoggerGUI(QWidget):
    def __init__(self):
        super().__init__()
        self.initUI()

        # Serial listener
        self.serial_listener = SerialListener()
        self.serial_listener.data_received.connect(self.handle_data)

        # Timer to update the graphs
        self.graph_update_timer = QTimer()
        self.graph_update_timer.timeout.connect(self.update_graphs)
        self.graph_update_timer.start(50)

        # Initialize data arrays
        self.data_array = []
        
    def initUI(self):
        # Window settings
        self.setWindowTitle('Data Logger GUI')
        self.setGeometry(100, 100, 1000, 800)

        # CDC log area
        self.cdc_log = QTextEdit(self)
        self.cdc_log.setReadOnly(True)
        self.cdc_log.setFont(QFont('Arial', 10))

        # Input and control buttons
        self.start_button = QPushButton('Start Logging', self)
        self.start_button.clicked.connect(self.start_logging)
        
        self.stop_button = QPushButton('Stop Logging', self)
        self.stop_button.clicked.connect(self.stop_logging)

        self.save_button = QPushButton('Save Data', self)
        self.save_button.clicked.connect(self.save_data)

        # Labels for received data
        self.data_label = QLabel('Received Data:')
        self.data_value_label = QLabel('No Data Received Yet')

        # Graph for received data
        self.data_graph = pg.PlotWidget(self)
        self.data_graph.setTitle('Data Graph')
        self.data_curve = self.data_graph.plot(pen='g', name='Data')

        # Layout
        self.layoutUI()

    def layoutUI(self):
        grid = QGridLayout()

        # Control buttons
        grid.addWidget(self.start_button, 0, 0)
        grid.addWidget(self.stop_button, 0, 1)
        grid.addWidget(self.save_button, 0, 2)

        # Data display
        grid.addWidget(self.data_label, 1, 0)
        grid.addWidget(self.data_value_label, 1, 1, 1, 2)

        # Graph for data
        grid.addWidget(self.data_graph, 2, 0, 1, 3)

        # CDC Log
        grid.addWidget(QLabel('CDC Log:'), 3, 0)
        grid.addWidget(self.cdc_log, 4, 0, 1, 3)

        self.setLayout(grid)

    def handle_data(self, message):
        self.cdc_log.append(f"Received: {message}")
        self.data_value_label.setText(f"Received: {message}")
        self.data_array.append(float(message))  # Assuming the message is a float

    def update_graphs(self):
        self.data_curve.setData(self.data_array)

    def start_logging(self):
        self.data_array.clear()  # Clear previous data
        self.cdc_log.append("Logging Started")

    def stop_logging(self):
        self.cdc_log.append("Logging Stopped")

    def save_data(self):
        if self.data_array:
            try:
                current_time = datetime.now().strftime('%Y-%m-%d_%H-%M-%S')
                file_name = f"Data_Logger_{current_time}.csv"
                file_path = os.path.join(os.getcwd(), file_name)

                # Write the data to a CSV file
                with open(file_path, mode='w', newline='') as file:
                    writer = csv.writer(file)
                    writer.writerow(['Data'])
                    for data in self.data_array:
                        writer.writerow([data])

                self.cdc_log.append(f"Data saved to {file_path}")
            except Exception as e:
                self.cdc_log.append(f"Error saving data: {e}")

if __name__ == '__main__':
    app = QApplication(sys.argv)
    ex = DataLoggerGUI()

    # Start the listener in a separate thread
    listener_thread = threading.Thread(target=listen_for_data, args=(ex.serial_listener,), daemon=True)
    listener_thread.start()

    ex.show()
    sys.exit(app.exec_())
