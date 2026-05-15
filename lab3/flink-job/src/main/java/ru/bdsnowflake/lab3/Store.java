package ru.bdsnowflake.lab3;

import java.sql.PreparedStatement;
import java.sql.SQLException;

public record Store(
        String storeKey,
        String name,
        String locationKey,
        String phone,
        String email
) {
    public static Store fromEvent(RawSaleEvent event) {
        Location location = Location.fromEvent(event);
        return new Store(
                PetShopStreamingJob.stableKey(
                        "store",
                        event.store_name,
                        event.store_location,
                        event.store_city,
                        event.store_country
                ),
                event.store_name,
                location.locationKey(),
                event.store_phone,
                event.store_email
        );
    }

    public static void bind(PreparedStatement statement, Store record) throws SQLException {
        statement.setString(1, record.storeKey);
        statement.setString(2, record.name);
        statement.setString(3, record.locationKey);
        statement.setString(4, record.phone);
        statement.setString(5, record.email);
    }
}
