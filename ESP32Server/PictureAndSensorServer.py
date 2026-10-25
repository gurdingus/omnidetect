
from flask import Flask, jsonify, Response
import board
import adafruit_bme680
import threading
import time
import subprocess
from datetime import datetime, timezone

app = Flask(__name__)

# ==================================================
# CONFIGURATION
# ==================================================

CAMERA_DEVICE = "/dev/video0"
CAMERA_WIDTH = "1280x720"
CAMERA_FPS = "15"

SERVER_HOST = "0.0.0.0"
SERVER_PORT = 5000

# ==================================================
# BME688 SENSOR SETUP
# ==================================================

i2c = board.I2C()


def initialize_sensor():
    """Try both common BME688 I2C addresses."""
    for address in (0x77, 0x76):
        try:
            device = adafruit_bme680.Adafruit_BME680_I2C(
                i2c, address=address
            )
            device.sea_level_pressure = 1013.25

            print(
                f"BME sensor initialized at {hex(address)}",
                flush=True
            )
            return device

        except Exception as exc:
            print(
                f"Could not initialize sensor at "
                f"{hex(address)}: {exc}",
                flush=True
            )

    raise RuntimeError(
        "BME688 not detected. Check I2C wiring and address."
    )


sensor = initialize_sensor()

latest_data = {}
sensor_error = None
data_lock = threading.Lock()


def sensor_reader():
    """Read sensor values in the background."""
    global latest_data, sensor_error

    while True:
        try:
            reading = {
                "sensor": "BME688",
                "timestamp": datetime.now(
                    timezone.utc
                ).isoformat(),
                "temperature_c": round(
                    sensor.temperature, 2
                ),
                "humidity_percent": round(
                    sensor.relative_humidity, 2
                ),
                "pressure_hpa": round(
                    sensor.pressure, 2
                ),
                "gas_resistance_ohms": int(sensor.gas),
                "sensor_ok": True
            }

            with data_lock:
                latest_data = reading
                sensor_error = None

            print("BME688:", reading, flush=True)

        except Exception as exc:
            with data_lock:
                sensor_error = str(exc)

            print("BME688 read error:", exc, flush=True)

        time.sleep(2)


# ==================================================
# AMCREST USB WEBCAM
# ==================================================

def capture_webcam_jpeg():
    """
    Capture a JPEG frame from the Amcrest USB webcam.

    Uses the tested working settings:
      - 1280x720 MJPEG
      - 15 FPS
      - Skip first 10 frames
      - Re-encode as JPEG at quality 3
    """

    command = [
        "ffmpeg",
        "-hide_banner",
        "-loglevel", "error",
        "-f", "v4l2",
        "-input_format", "mjpeg",
        "-video_size", CAMERA_WIDTH,
        "-framerate", CAMERA_FPS,
        "-i", CAMERA_DEVICE,
        "-vf", r"select=gte(n\,10)",
        "-frames:v", "1",
        "-c:v", "mjpeg",
        "-q:v", "3",
        "-f", "image2pipe",
        "-vcodec", "mjpeg",
        "pipe:1"
    ]

    result = subprocess.run(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        timeout=30,
        check=False
    )

    if result.returncode != 0 or not result.stdout:
        details = result.stderr.decode(
            "utf-8", errors="replace"
        )

        raise RuntimeError(
            details or "No image returned by webcam"
        )

    # Confirm FFmpeg returned JPEG data.
    if not result.stdout.startswith(b"\xff\xd8"):
        raise RuntimeError(
            "FFmpeg output does not start with a JPEG marker"
        )

    return result.stdout


# Prevent simultaneous requests from accessing the webcam.
camera_lock = threading.Lock()


# ==================================================
# DASHBOARD
# ==================================================

@app.route("/", methods=["GET"])
def home():
    return """
    <!DOCTYPE html>
    <html>
    <head>
        <title>OmniDetect Monitor</title>
        <meta name="viewport"
              content="width=device-width, initial-scale=1">

        <style>
            body {
                font-family: Arial, sans-serif;
                max-width: 850px;
                margin: 30px auto;
                padding: 0 16px;
                background: #f5f6f8;
                color: #222;
            }

            section {
                background: white;
                border-radius: 10px;
                padding: 18px;
                margin-bottom: 20px;
                box-shadow: 0 2px 8px #00000012;
            }

            img {
                display: block;
                width: 100%;
                height: auto;
                border-radius: 8px;
                background: #eee;
            }

            pre {
                white-space: pre-wrap;
                overflow-wrap: anywhere;
            }

            button {
                padding: 10px 16px;
                cursor: pointer;
            }

            a {
                margin-right: 10px;
            }
        </style>
    </head>

    <body>
        <h1>OmniDetect Monitor</h1>

        <section>
            <h2>BME688 Sensor</h2>
            <p>Readings refresh every two seconds.</p>

            <pre id="sensor">Loading sensor data...</pre>

            <a href="/sensor" target="_blank">
                Sensor JSON
            </a>
            <a href="/health" target="_blank">
                Health
            </a>
        </section>

        <section>
            <h2>Amcrest Webcam</h2>
            <p>Live snapshot on request.</p>

            <img id="camera"
                 alt="Amcrest webcam snapshot">

            <p>
                <button onclick="refreshPicture()">
                    Capture new picture
                </button>
                <a href="/picture" target="_blank">
                    Open picture directly
                </a>
            </p>

            <p id="cameraStatus">Ready.</p>
        </section>

        <script>
            async function refreshSensor() {
                try {
                    const response = await fetch(
                        '/sensor',
                        { cache: 'no-store' }
                    );

                    const data = await response.json();

                    document.getElementById('sensor').textContent =
                        JSON.stringify(data, null, 2);

                } catch (error) {
                    document.getElementById('sensor').textContent =
                        'Sensor request failed: ' + error;
                }
            }

            function refreshPicture() {
                const img = document.getElementById('camera');
                const status =
                    document.getElementById('cameraStatus');

                status.textContent = 'Capturing image...';

                img.onload = function() {
                    status.textContent =
                        'Image captured successfully.';
                };

                img.onerror = function() {
                    status.textContent =
                        'Image capture failed. Check server logs.';
                };

                img.src = '/picture?t=' + Date.now();
            }

            refreshSensor();
            refreshPicture();

            setInterval(refreshSensor, 2000);
        </script>
    </body>
    </html>
    """


# ==================================================
# BME688 JSON ENDPOINT
# ==================================================

@app.route("/sensor", methods=["GET"])
def get_sensor():
    with data_lock:
        data = dict(latest_data)
        error = sensor_error

    if data:
        return jsonify(data), 200

    return jsonify({
        "sensor": "BME688",
        "sensor_ok": False,
        "error": error or "Waiting for first sensor reading"
    }), 503


# ==================================================
# WEBCAM JPEG ENDPOINT
# ==================================================

@app.route("/picture", methods=["GET"])
def get_picture():
    try:
        with camera_lock:
            jpeg = capture_webcam_jpeg()

        response = Response(
            jpeg,
            status=200,
            mimetype="image/jpeg"
        )

        response.headers["Cache-Control"] = (
            "no-store, no-cache, must-revalidate"
        )
        response.headers["Pragma"] = "no-cache"
        response.headers["Content-Disposition"] = (
            'inline; filename="amcrest.jpg"'
        )

        return response

    except subprocess.TimeoutExpired:
        return jsonify({
            "error": "Webcam capture timed out"
        }), 504

    except Exception as exc:
        print("Webcam error:", str(exc), flush=True)

        return jsonify({
            "error": "Webcam capture failed",
            "details": str(exc)
        }), 503


# ==================================================
# HEALTH ENDPOINT
# ==================================================

@app.route("/health", methods=["GET"])
def health():
    with data_lock:
        sensor_ok = (
            bool(latest_data) and sensor_error is None
        )

    return jsonify({
        "server": "running",
        "sensor_ok": sensor_ok,
        "camera_device": CAMERA_DEVICE,
        "sensor_endpoint": "/sensor",
        "picture_endpoint": "/picture"
    }), 200


# ==================================================
# START SERVER
# ==================================================

if __name__ == "__main__":
    reader = threading.Thread(
        target=sensor_reader,
        daemon=True
    )
    reader.start()

    print("\nOmniDetect server starting...", flush=True)
    print("Dashboard: http://<PI_IP>:5000/", flush=True)
    print("Sensor:    http://<PI_IP>:5000/sensor", flush=True)
    print("Picture:   http://<PI_IP>:5000/picture", flush=True)
    print("Health:    http://<PI_IP>:5000/health\n", flush=True)

    app.run(
        host=SERVER_HOST,
        port=SERVER_PORT,
        debug=False,
        threaded=True
    )


