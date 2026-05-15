package ru.bdsnowflake.lab3;

import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.apache.flink.api.common.eventtime.WatermarkStrategy;
import org.apache.flink.api.common.functions.MapFunction;
import org.apache.flink.api.common.serialization.SimpleStringSchema;
import org.apache.flink.api.common.typeinfo.TypeHint;
import org.apache.flink.api.common.typeinfo.TypeInformation;
import org.apache.flink.connector.jdbc.JdbcConnectionOptions;
import org.apache.flink.connector.jdbc.JdbcExecutionOptions;
import org.apache.flink.connector.jdbc.JdbcSink;
import org.apache.flink.connector.kafka.source.KafkaSource;
import org.apache.flink.connector.kafka.source.enumerator.initializer.OffsetsInitializer;
import org.apache.flink.streaming.api.datastream.DataStream;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.Arrays;
import java.util.HexFormat;
import java.util.Locale;

public class PetShopStreamingJob {
    private static final ObjectMapper OBJECT_MAPPER = new ObjectMapper()
            .configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);
    private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("M/d/yyyy", Locale.US);

    public static void main(String[] args) throws Exception {
        String kafkaBootstrap = env("KAFKA_BOOTSTRAP_SERVERS", "kafka:19092");
        String kafkaTopic = env("KAFKA_TOPIC", "petshop.sales.raw");
        String postgresUrl = env("POSTGRES_JDBC_URL", "jdbc:postgresql://postgres:5432/pet_shop");
        String postgresUser = env("POSTGRES_USER", "pet_user");
        String postgresPassword = env("POSTGRES_PASSWORD", "pet_password");

        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
        env.enableCheckpointing(10_000L);

        KafkaSource<String> source = KafkaSource.<String>builder()
                .setBootstrapServers(kafkaBootstrap)
                .setTopics(kafkaTopic)
                .setGroupId("lab3-flink-consumer")
                .setStartingOffsets(OffsetsInitializer.earliest())
                .setValueOnlyDeserializer(new SimpleStringSchema())
                .build();

        DataStream<RawSaleEvent> rawEvents = env.fromSource(source, WatermarkStrategy.noWatermarks(), "kafka-source")
                .map((MapFunction<String, RawSaleEvent>) value -> OBJECT_MAPPER.readValue(value, RawSaleEvent.class),
                        TypeInformation.of(RawSaleEvent.class));

        // --- Измерения (dim) ---

        DataStream<Customer> customerStream = rawEvents
                .map(Customer::fromEvent, TypeInformation.of(Customer.class));

        DataStream<PetType> petTypeStream = rawEvents
                .map(PetType::fromEvent, TypeInformation.of(PetType.class))
                .returns(TypeInformation.of(new TypeHint<PetType>() {}));

        DataStream<PetBreed> petBreedStream = rawEvents
                .map(PetBreed::fromEvent, TypeInformation.of(PetBreed.class))
                .returns(TypeInformation.of(new TypeHint<PetBreed>() {}));

        DataStream<Pet> petStream = rawEvents
                .map(Pet::fromEvent, TypeInformation.of(Pet.class));

        DataStream<Seller> sellerStream = rawEvents
                .map(Seller::fromEvent, TypeInformation.of(Seller.class));

        DataStream<Category> categoryStream = rawEvents
                .map(Category::fromEvent, TypeInformation.of(Category.class))
                .returns(TypeInformation.of(new TypeHint<Category>() {}));

        DataStream<Brand> brandStream = rawEvents
                .map(Brand::fromEvent, TypeInformation.of(Brand.class))
                .returns(TypeInformation.of(new TypeHint<Brand>() {}));

        DataStream<Product> productStream = rawEvents
                .map(Product::fromEvent, TypeInformation.of(Product.class));

        DataStream<Location> locationStream = rawEvents
                .map(Location::fromEvent, TypeInformation.of(Location.class));

        DataStream<Store> storeStream = rawEvents
                .map(Store::fromEvent, TypeInformation.of(Store.class));

        DataStream<Supplier> supplierStream = rawEvents
                .map(Supplier::fromEvent, TypeInformation.of(Supplier.class));

        // --- Факты ---

        DataStream<FactSale> factStream = rawEvents
                .map(FactSale::fromEvent, TypeInformation.of(FactSale.class));

        // --- Настройки JDBC ---

        JdbcConnectionOptions connectionOptions = new JdbcConnectionOptions.JdbcConnectionOptionsBuilder()
                .withUrl(postgresUrl)
                .withDriverName("org.postgresql.Driver")
                .withUsername(postgresUser)
                .withPassword(postgresPassword)
                .build();

        JdbcExecutionOptions executionOptions = JdbcExecutionOptions.builder()
                .withBatchSize(100)
                .withBatchIntervalMs(2_000)
                .withMaxRetries(5)
                .build();

        // --- Sink'и для измерений ---

        customerStream.addSink(JdbcSink.sink(
                SqlStatements.UPSERT_CUSTOMER,
                Customer::bind,
                executionOptions,
                connectionOptions
        )).name("postgres-dim-customer");

        petTypeStream.addSink(JdbcSink.sink(
                SqlStatements.UPSERT_PET_TYPE,
                PetType::bind,
                executionOptions,
                connectionOptions
        )).name("postgres-dim-pet-type");

        petBreedStream.addSink(JdbcSink.sink(
                SqlStatements.UPSERT_PET_BREED,
                PetBreed::bind,
                executionOptions,
                connectionOptions
        )).name("postgres-dim-pet-breed");

        petStream.addSink(JdbcSink.sink(
                SqlStatements.UPSERT_PET,
                Pet::bind,
                executionOptions,
                connectionOptions
        )).name("postgres-dim-pet");

        sellerStream.addSink(JdbcSink.sink(
                SqlStatements.UPSERT_SELLER,
                Seller::bind,
                executionOptions,
                connectionOptions
        )).name("postgres-dim-seller");

        categoryStream.addSink(JdbcSink.sink(
                SqlStatements.UPSERT_CATEGORY,
                Category::bind,
                executionOptions,
                connectionOptions
        )).name("postgres-dim-category");

        brandStream.addSink(JdbcSink.sink(
                SqlStatements.UPSERT_BRAND,
                Brand::bind,
                executionOptions,
                connectionOptions
        )).name("postgres-dim-brand");

        productStream.addSink(JdbcSink.sink(
                SqlStatements.UPSERT_PRODUCT,
                Product::bind,
                executionOptions,
                connectionOptions
        )).name("postgres-dim-product");

        locationStream.addSink(JdbcSink.sink(
                SqlStatements.UPSERT_LOCATION,
                Location::bind,
                executionOptions,
                connectionOptions
        )).name("postgres-dim-location");

        storeStream.addSink(JdbcSink.sink(
                SqlStatements.UPSERT_STORE,
                Store::bind,
                executionOptions,
                connectionOptions
        )).name("postgres-dim-store");

        supplierStream.addSink(JdbcSink.sink(
                SqlStatements.UPSERT_SUPPLIER,
                Supplier::bind,
                executionOptions,
                connectionOptions
        )).name("postgres-dim-supplier");

        // --- Sink для фактов ---

        factStream.addSink(JdbcSink.sink(
                SqlStatements.UPSERT_FACT_SALE,
                FactSale::bind,
                executionOptions,
                connectionOptions
        )).name("postgres-fact-sales");

        env.execute("LR3 Snowflake Kafka -> Flink -> PostgreSQL");
    }

    private static String env(String key, String fallback) {
        String value = System.getenv(key);
        return value == null || value.isBlank() ? fallback : value;
    }

    static String stableKey(String prefix, String... values) {
        try {
            MessageDigest digest = MessageDigest.getInstance("MD5");
            String joined = String.join("|", Arrays.stream(values)
                    .map(value -> value == null ? "" : value)
                    .toArray(String[]::new));
            byte[] hash = digest.digest(joined.getBytes(StandardCharsets.UTF_8));
            return prefix + "_" + HexFormat.of().formatHex(hash);
        } catch (Exception ex) {
            throw new IllegalStateException("Cannot create stable key", ex);
        }
    }

    static BigDecimal decimal(String value) {
        return value == null || value.isBlank() ? null : new BigDecimal(value.trim());
    }

    static Integer integer(String value) {
        return value == null || value.isBlank() ? null : Integer.valueOf(value.trim());
    }

    static Long longValue(String value) {
        return value == null || value.isBlank() ? null : Long.valueOf(value.trim());
    }

    static LocalDate date(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        try {
            return LocalDate.parse(value.trim(), DATE_FORMATTER);
        } catch (DateTimeParseException ex) {
            return null;
        }
    }
}
