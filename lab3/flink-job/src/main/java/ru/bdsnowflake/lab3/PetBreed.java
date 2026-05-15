package ru.bdsnowflake.lab3;

import java.sql.PreparedStatement;
import java.sql.SQLException;

public record PetBreed(
        String petBreedKey,
        String petBreedName,
        String petCategory
) {
    public static PetBreed fromEvent(RawSaleEvent event) {
        String breed = event.customer_pet_breed;
        if (breed == null || breed.isBlank()) {
            return null;
        }
        return new PetBreed(
                PetShopStreamingJob.stableKey("pet_breed", breed, event.pet_category),
                breed,
                event.pet_category
        );
    }

    public static void bind(PreparedStatement statement, PetBreed record) throws SQLException {
        statement.setString(1, record.petBreedKey);
        statement.setString(2, record.petBreedName);
        statement.setString(3, record.petCategory);
    }
}
