import csv
import json
import logging
import os
import time
from collections.abc import Generator
from pathlib import Path

from kafka import KafkaProducer

logger = logging.getLogger(__name__)


def create_producer() -> KafkaProducer:
    bootstrap_servers = os.getenv("KAFKA_BOOTSTRAP_SERVERS", "localhost:9094")
    for attempt in range(1, 31):
        try:
            return KafkaProducer(
                bootstrap_servers=bootstrap_servers,
                value_serializer=lambda value: json.dumps(value, ensure_ascii=False).encode("utf-8"),
                acks="all",
                retries=10,
            )
        except Exception as exc:  # noqa: BLE001
            logger.warning("Kafka not ready yet (attempt %d/30): %s", attempt, exc)
            time.sleep(5)
    raise RuntimeError("Kafka bootstrap failed after 30 attempts")


def normalize_value(value: str | None) -> str | None:
    if value is None:
        return None
    value = value.strip()
    return value or None


def iter_rows(data_dir: Path) -> Generator[dict[str, str | None]]:
    for file_path in sorted(data_dir.glob("*.csv")):
        logger.info("Reading %s", file_path.name)
        with file_path.open("r", encoding="utf-8", newline="") as csv_file:
            reader = csv.DictReader(csv_file)
            for row in reader:
                payload = {key: normalize_value(value) for key, value in row.items()}
                payload["source_file"] = file_path.name
                yield payload


def main() -> None:
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(message)s",
    )

    topic = os.getenv("KAFKA_TOPIC", "petshop.sales.raw")
    data_dir = Path(os.getenv("DATA_DIR", "/data"))
    send_delay_ms = int(os.getenv("SEND_DELAY_MS", "0"))

    producer = create_producer()
    sent_messages = 0

    for payload in iter_rows(data_dir):
        try:
            future = producer.send(topic, payload)
            future.get(timeout=10)
        except Exception as exc:
            logger.error("Failed to send message: %s", exc)
            raise
        sent_messages += 1
        if send_delay_ms > 0:
            time.sleep(send_delay_ms / 1000)

    producer.flush()
    producer.close()
    logger.info("Finished sending %d messages to topic '%s'", sent_messages, topic)


if __name__ == "__main__":
    main()
