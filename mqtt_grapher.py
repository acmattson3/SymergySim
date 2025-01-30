import paho.mqtt.client as mqtt
import json
import matplotlib.pyplot as plt
import matplotlib.animation as animation
from collections import deque

# MQTT broker details
BROKER = "test.mosquitto.org"
TOPIC = "symergygrid/components/generator1/#"  # Subscribe to all subtopics

# Data storage
history_length = 100  # Number of points to keep in the graph
data = {
    "demand": deque([0] * history_length, maxlen=history_length),
    "voltage": deque([0] * history_length, maxlen=history_length),
    "power": deque([0] * history_length, maxlen=history_length),
    "energy": deque([0] * history_length, maxlen=history_length),
    "time": deque(range(-history_length, 0), maxlen=history_length)  # Time axis
}

# MQTT callback function
def on_message(client, userdata, msg):
    try:
        payload = json.loads(msg.payload.decode("utf-8"))  # Parse JSON
        value = payload.get("value", 0)  # Extract numerical value

        if "demand" in msg.topic:
            data["demand"].append(value)
        elif "voltage" in msg.topic:
            data["voltage"].append(value)
        elif "power" in msg.topic:
            data["power"].append(value)
        elif "energy" in msg.topic:
            data["energy"].append(value)

        # Increment time index
        data["time"].append(data["time"][-1] + 0.2)

    except json.JSONDecodeError:
        print(f"Invalid JSON received: {msg.payload.decode('utf-8')}")

# Set up MQTT client
client = mqtt.Client()
client.on_message = on_message
client.connect(BROKER, 1883, 60)
client.subscribe(TOPIC)
client.loop_start()

# Set up the plot with dual y-axes
fig, ax1 = plt.subplots()
ax2 = ax1.twinx()  # Create a second y-axis

# Titles and labels
ax1.set_title("Live MQTT Data from Symergy Grid")
ax1.set_xlabel("Time")
ax1.set_ylabel("Demand (A), Voltage (V), Power (kW)")
ax2.set_ylabel("Energy (kWh)")

# Plot lines
lines = {
    "demand": ax1.plot([], [], label="Demand (A)", color="tab:blue")[0],
    "voltage": ax1.plot([], [], label="Voltage (V)", color="tab:orange")[0],
    "power": ax1.plot([], [], label="Power (kW)", color="tab:green")[0],
    "energy": ax2.plot([], [], label="Energy (kWh)", color="tab:red")[0],  # Separate axis
}

ax1.legend(loc="upper left")
ax2.legend(loc="upper right")

# Update function for animation
def update(frame):
    ax1.clear()
    ax2.clear()

    # Titles and labels
    ax1.set_title("Live MQTT Data from Symergy Grid")
    ax1.set_xlabel("Time")
    ax1.set_ylabel("Demand (A), Voltage (V), Power (kW)")
    ax2.set_ylabel("Energy (kWh)")

    # X-axis limits
    ax1.set_xlim(min(data["time"]), max(data["time"]))

    # Y-axis limits (auto-adjusted with padding)
    min_y1 = min([min(data[key]) for key in ["demand", "voltage", "power"]])
    max_y1 = max([max(data[key]) for key in ["demand", "voltage", "power"]])
    ax1.set_ylim(min_y1 - abs(min_y1 * 0.1), max_y1 + abs(max_y1 * 0.1))

    min_y2 = min(data["energy"])
    max_y2 = max(data["energy"])
    ax2.set_ylim(min_y2 - abs(min_y2 * 0.1), max_y2 + abs(max_y2 * 0.1))

    # Plot each value
    for key in ["demand", "voltage", "power"]:
        ax1.plot(data["time"], data[key], label=key)
    ax2.plot(data["time"], data["energy"], label="Energy", color="tab:red")

    ax1.legend(loc="upper left")
    ax2.legend(loc="upper right")

ani = animation.FuncAnimation(fig, update, interval=1000)

plt.show()

# Stop MQTT loop when closing the plot
client.loop_stop()
client.disconnect()
