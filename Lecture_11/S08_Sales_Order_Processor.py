"""Sales Order Validation & Processing Program for Session 08."""

LARGE_ORDER_THRESHOLD = 950.0


def read_required_text(prompt):
    """Read non-blank text and return it without surrounding whitespace."""
    while True:
        value = input(prompt).strip()

        if value == "":
            print("This field cannot be blank.")
            continue

        return value


def read_positive_number(prompt):
    """Read and return a positive floating-point number."""
    while True:
        raw_value = input(prompt)

        try:
            value = float(raw_value)
        except ValueError:
            print("Please enter a number.")
            continue
        else:
            if value <= 0:
                print("Value must be greater than 0.")
                continue

            return value


def read_positive_int(prompt):
    """Read and return a positive integer."""
    while True:
        raw_value = input(prompt)

        try:
            value = int(raw_value)
        except ValueError:
            print("Please enter a whole number.")
            continue
        else:
            if value <= 0:
                print("Value must be greater than 0.")
                continue

            return value


def read_percentage(prompt):
    """Read and return a percentage from 0 to 100 inclusive."""
    while True:
        raw_value = input(prompt)

        try:
            value = float(raw_value)
        except ValueError:
            print("Please enter a number.")
            continue
        else:
            if value < 0:
                print("Percentage cannot be below 0.")
                continue
            elif value > 100:
                print("Percentage cannot be above 100.")
                continue

            return value


def calculate_subtotal(unit_price, quantity):
    """Return the subtotal before discount and tax."""
    subtotal = unit_price * quantity
    return subtotal


def apply_discount(subtotal, discount_pct):
    """Return the subtotal after applying the percentage discount."""
    discount_amount = subtotal * discount_pct / 100
    discounted_subtotal = subtotal - discount_amount
    return discounted_subtotal


def apply_tax(discounted_subtotal, tax_pct):
    """Return the final amount after applying tax."""
    tax_amount = discounted_subtotal * tax_pct / 100
    final_total = discounted_subtotal + tax_amount
    return final_total


def calculate_final_total(unit_price, quantity, discount_pct, tax_pct):
    """Compose the calculation helpers and return the final order total."""
    subtotal = calculate_subtotal(unit_price, quantity)
    discounted_subtotal = apply_discount(subtotal, discount_pct)
    final_total = apply_tax(discounted_subtotal, tax_pct)
    return final_total


def classify_order(final_total, threshold=LARGE_ORDER_THRESHOLD):
    """Return 'large' when the final total reaches the threshold."""
    if final_total >= threshold:
        return "large"
    else:
        return "standard"


def display_summary(customer_name, product_name, unit_price, quantity,
                    discount_pct, tax_pct, final_total, classification):
    """Display the completed order summary."""
    print("\n--- Order Summary ---")
    print("Customer:", customer_name)
    print("Product:", product_name)
    print("Unit price:", unit_price)
    print("Quantity:", quantity)
    print("Discount %:", discount_pct)
    print("Tax %:", tax_pct)
    print("Final total:", final_total)
    print("Classification:", classification)


def process_order():
    """Read, validate, calculate, classify, and display one order."""
    customer_name = read_required_text("Customer name: ")
    product_name = read_required_text("Product name: ")
    unit_price = read_positive_number("Unit price: ")
    quantity = read_positive_int("Quantity: ")
    discount_pct = read_percentage("Discount %: ")
    tax_pct = read_percentage("Tax %: ")

    final_total = calculate_final_total(
        unit_price,
        quantity,
        discount_pct,
        tax_pct,
    )
    classification = classify_order(final_total)

    display_summary(
        customer_name,
        product_name,
        unit_price,
        quantity,
        discount_pct,
        tax_pct,
        final_total,
        classification,
    )


def main():
    """Coordinate repeated order processing until the user chooses to stop."""
    print("Sales Order Validation & Processing Program")

    while True:
        process_order()

        another_order = input("Process another order? (y/n): ").strip().lower()

        if another_order != "y":
            print("Program finished.")
            break


if __name__ == "__main__":
    main()
