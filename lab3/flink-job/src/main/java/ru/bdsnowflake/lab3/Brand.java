package ru.bdsnowflake.lab3;

import java.sql.PreparedStatement;
import java.sql.SQLException;

public record Brand(
        String brandKey,
        String brandName
) {
    public static Brand fromEvent(RawSaleEvent event) {
        String brand = event.product_brand;
        if (brand == null || brand.isBlank()) {
            return null;
        }
        return new Brand(
                PetShopStreamingJob.stableKey("brand", brand),
                brand
        );
    }

    public static void bind(PreparedStatement statement, Brand record) throws SQLException {
        statement.setString(1, record.brandKey);
        statement.setString(2, record.brandName);
    }
}
