package ru.bdsnowflake.lab3;

import java.sql.PreparedStatement;
import java.sql.SQLException;

public record Pet(
        String petKey,
        String customerKey,
        String petTypeKey,
        String petBreedKey,
        String petName
) {
    public static Pet fromEvent(RawSaleEvent event) {
        Customer customer = Customer.fromEvent(event);
        PetType petType = PetType.fromEvent(event);
        PetBreed petBreed = PetBreed.fromEvent(event);
        return new Pet(
                PetShopStreamingJob.stableKey(
                        "pet",
                        customer.customerKey(),
                        event.customer_pet_type,
                        event.customer_pet_name,
                        event.customer_pet_breed
                ),
                customer.customerKey(),
                petType != null ? petType.petTypeKey() : null,
                petBreed != null ? petBreed.petBreedKey() : null,
                event.customer_pet_name
        );
    }

    public static void bind(PreparedStatement statement, Pet record) throws SQLException {
        statement.setString(1, record.petKey);
        statement.setString(2, record.customerKey);
        statement.setString(3, record.petTypeKey);
        statement.setString(4, record.petBreedKey);
        statement.setString(5, record.petName);
    }
}
