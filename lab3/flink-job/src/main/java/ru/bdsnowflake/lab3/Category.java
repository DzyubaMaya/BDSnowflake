package ru.bdsnowflake.lab3;

import java.sql.PreparedStatement;
import java.sql.SQLException;

public record Category(
        String categoryKey,
        String categoryName
) {
    public static Category fromEvent(RawSaleEvent event) {
        String cat = event.product_category;
        if (cat == null || cat.isBlank()) {
            return null;
        }
        return new Category(
                PetShopStreamingJob.stableKey("category", cat),
                cat
        );
    }

    public static void bind(PreparedStatement statement, Category record) throws SQLException {
        statement.setString(1, record.categoryKey);
        statement.setString(2, record.categoryName);
    }
}
