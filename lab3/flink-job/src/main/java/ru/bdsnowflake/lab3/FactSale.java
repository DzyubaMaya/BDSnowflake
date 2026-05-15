package ru.bdsnowflake.lab3;

import java.sql.PreparedStatement;
import java.sql.SQLException;

public record FactSale(
        String saleKey,
        String sourceFile,
        Long saleSourceRowId,
        java.time.LocalDate saleDate,
        Long saleCustomerId,
        Long saleSellerId,
        Long saleProductId,
        Integer saleQuantity,
        java.math.BigDecimal saleTotalPrice,
        String customerKey,
        String petKey,
        String sellerKey,
        String productKey,
        String storeKey,
        String supplierKey
) {
    public static FactSale fromEvent(RawSaleEvent event) {
        Customer customer = Customer.fromEvent(event);
        Pet pet = Pet.fromEvent(event);
        Seller seller = Seller.fromEvent(event);
        Product product = Product.fromEvent(event);
        Store store = Store.fromEvent(event);
        Supplier supplier = Supplier.fromEvent(event);
        return new FactSale(
                PetShopStreamingJob.stableKey("sale", event.source_file, event.id),
                event.source_file,
                PetShopStreamingJob.longValue(event.id),
                PetShopStreamingJob.date(event.sale_date),
                PetShopStreamingJob.longValue(event.sale_customer_id),
                PetShopStreamingJob.longValue(event.sale_seller_id),
                PetShopStreamingJob.longValue(event.sale_product_id),
                PetShopStreamingJob.integer(event.sale_quantity),
                PetShopStreamingJob.decimal(event.sale_total_price),
                customer.customerKey(),
                pet.petKey(),
                seller.sellerKey(),
                product.productKey(),
                store.storeKey(),
                supplier.supplierKey()
        );
    }

    public static void bind(PreparedStatement statement, FactSale record) throws SQLException {
        statement.setString(1, record.saleKey);
        statement.setString(2, record.sourceFile);
        if (record.saleSourceRowId == null) {
            statement.setNull(3, java.sql.Types.BIGINT);
        } else {
            statement.setLong(3, record.saleSourceRowId);
        }
        if (record.saleDate == null) {
            statement.setNull(4, java.sql.Types.DATE);
        } else {
            statement.setDate(4, java.sql.Date.valueOf(record.saleDate));
        }
        if (record.saleCustomerId == null) {
            statement.setNull(5, java.sql.Types.BIGINT);
        } else {
            statement.setLong(5, record.saleCustomerId);
        }
        if (record.saleSellerId == null) {
            statement.setNull(6, java.sql.Types.BIGINT);
        } else {
            statement.setLong(6, record.saleSellerId);
        }
        if (record.saleProductId == null) {
            statement.setNull(7, java.sql.Types.BIGINT);
        } else {
            statement.setLong(7, record.saleProductId);
        }
        if (record.saleQuantity == null) {
            statement.setNull(8, java.sql.Types.INTEGER);
        } else {
            statement.setInt(8, record.saleQuantity);
        }
        statement.setBigDecimal(9, record.saleTotalPrice);
        statement.setString(10, record.customerKey);
        statement.setString(11, record.petKey);
        statement.setString(12, record.sellerKey);
        statement.setString(13, record.productKey);
        statement.setString(14, record.storeKey);
        statement.setString(15, record.supplierKey);
    }
}
