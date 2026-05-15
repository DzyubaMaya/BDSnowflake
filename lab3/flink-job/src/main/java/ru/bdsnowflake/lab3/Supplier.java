package ru.bdsnowflake.lab3;

import java.sql.PreparedStatement;
import java.sql.SQLException;

public record Supplier(
        String supplierKey,
        String name,
        String contact,
        String email,
        String phone,
        String address,
        String city,
        String country
) {
    public static Supplier fromEvent(RawSaleEvent event) {
        return new Supplier(
                PetShopStreamingJob.stableKey(
                        "supplier",
                        event.supplier_name,
                        event.supplier_email,
                        event.supplier_phone,
                        event.supplier_country
                ),
                event.supplier_name,
                event.supplier_contact,
                event.supplier_email,
                event.supplier_phone,
                event.supplier_address,
                event.supplier_city,
                event.supplier_country
        );
    }

    public static void bind(PreparedStatement statement, Supplier record) throws SQLException {
        statement.setString(1, record.supplierKey);
        statement.setString(2, record.name);
        statement.setString(3, record.contact);
        statement.setString(4, record.email);
        statement.setString(5, record.phone);
        statement.setString(6, record.address);
        statement.setString(7, record.city);
        statement.setString(8, record.country);
    }
}
