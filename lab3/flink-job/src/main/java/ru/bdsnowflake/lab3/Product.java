package ru.bdsnowflake.lab3;

import java.sql.PreparedStatement;
import java.sql.SQLException;

public record Product(
        String productKey,
        Long productSourceId,
        String name,
        String categoryKey,
        String brandKey,
        java.math.BigDecimal price,
        Integer quantity,
        java.math.BigDecimal weight,
        String color,
        String size,
        String material,
        String description,
        java.math.BigDecimal rating,
        Integer reviews,
        java.time.LocalDate releaseDate,
        java.time.LocalDate expiryDate
) {
    public static Product fromEvent(RawSaleEvent event) {
        Category category = Category.fromEvent(event);
        Brand brand = Brand.fromEvent(event);
        return new Product(
                PetShopStreamingJob.stableKey(
                        "product",
                        event.product_name,
                        event.product_category,
                        event.product_brand,
                        event.product_color,
                        event.product_size
                ),
                PetShopStreamingJob.longValue(event.sale_product_id),
                event.product_name,
                category != null ? category.categoryKey() : null,
                brand != null ? brand.brandKey() : null,
                PetShopStreamingJob.decimal(event.product_price),
                PetShopStreamingJob.integer(event.product_quantity),
                PetShopStreamingJob.decimal(event.product_weight),
                event.product_color,
                event.product_size,
                event.product_material,
                event.product_description,
                PetShopStreamingJob.decimal(event.product_rating),
                PetShopStreamingJob.integer(event.product_reviews),
                PetShopStreamingJob.date(event.product_release_date),
                PetShopStreamingJob.date(event.product_expiry_date)
        );
    }

    public static void bind(PreparedStatement statement, Product record) throws SQLException {
        statement.setString(1, record.productKey);
        if (record.productSourceId == null) {
            statement.setNull(2, java.sql.Types.BIGINT);
        } else {
            statement.setLong(2, record.productSourceId);
        }
        statement.setString(3, record.name);
        statement.setString(4, record.categoryKey);
        statement.setString(5, record.brandKey);
        statement.setBigDecimal(6, record.price);
        if (record.quantity == null) {
            statement.setNull(7, java.sql.Types.INTEGER);
        } else {
            statement.setInt(7, record.quantity);
        }
        statement.setBigDecimal(8, record.weight);
        statement.setString(9, record.color);
        statement.setString(10, record.size);
        statement.setString(11, record.material);
        statement.setString(12, record.description);
        statement.setBigDecimal(13, record.rating);
        if (record.reviews == null) {
            statement.setNull(14, java.sql.Types.INTEGER);
        } else {
            statement.setInt(14, record.reviews);
        }
        if (record.releaseDate == null) {
            statement.setNull(15, java.sql.Types.DATE);
        } else {
            statement.setDate(15, java.sql.Date.valueOf(record.releaseDate));
        }
        if (record.expiryDate == null) {
            statement.setNull(16, java.sql.Types.DATE);
        } else {
            statement.setDate(16, java.sql.Date.valueOf(record.expiryDate));
        }
    }
}
