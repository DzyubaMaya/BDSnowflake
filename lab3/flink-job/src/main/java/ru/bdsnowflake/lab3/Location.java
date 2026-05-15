package ru.bdsnowflake.lab3;

import java.sql.PreparedStatement;
import java.sql.SQLException;

public record Location(
        String locationKey,
        String locationName,
        String city,
        String state,
        String country
) {
    public static Location fromEvent(RawSaleEvent event) {
        return new Location(
                PetShopStreamingJob.stableKey(
                        "location",
                        event.store_location,
                        event.store_city,
                        event.store_state,
                        event.store_country
                ),
                event.store_location,
                event.store_city,
                event.store_state,
                event.store_country
        );
    }

    public static void bind(PreparedStatement statement, Location record) throws SQLException {
        statement.setString(1, record.locationKey);
        statement.setString(2, record.locationName);
        statement.setString(3, record.city);
        statement.setString(4, record.state);
        statement.setString(5, record.country);
    }
}
