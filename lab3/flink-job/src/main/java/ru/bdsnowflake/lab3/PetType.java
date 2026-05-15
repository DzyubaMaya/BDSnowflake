package ru.bdsnowflake.lab3;

import java.sql.PreparedStatement;
import java.sql.SQLException;

public record PetType(
        String petTypeKey,
        String petTypeName
) {
    public static PetType fromEvent(RawSaleEvent event) {
        String type = event.customer_pet_type;
        if (type == null || type.isBlank()) {
            return null;
        }
        return new PetType(
                PetShopStreamingJob.stableKey("pet_type", type),
                type
        );
    }

    public static void bind(PreparedStatement statement, PetType record) throws SQLException {
        statement.setString(1, record.petTypeKey);
        statement.setString(2, record.petTypeName);
    }
}
