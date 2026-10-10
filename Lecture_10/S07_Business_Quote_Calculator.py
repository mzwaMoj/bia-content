"""Sales Quote & Order Summary Utility — Session 07 companion script.

This beginner-readable script uses direct statements from top to bottom.
It requires only standard Python 3 built-ins.
"""

# Collect text input.
customer_name = input("Customer name: ")
product_name = input("Product name: ")

# Convert numeric text before using it in calculations.
unit_price = float(input("Unit price: "))
quantity = int(input("Quantity: "))
discount_pct = float(input("Discount percentage: "))
tax_pct = float(input("Tax percentage: "))
large_order_threshold = 950.0

# Clean names for the summary and order code.
customer_name = customer_name.strip().title()
product_name = product_name.strip().title()

# Calculate the quote in the approved order.
subtotal = unit_price * quantity
discount_amount = subtotal * discount_pct / 100
discounted_subtotal = subtotal - discount_amount
tax_amount = discounted_subtotal * tax_pct / 100
final_total = discounted_subtotal + tax_amount
is_large_order = final_total >= large_order_threshold

# This introductory order code assumes both cleaned names are non-empty.
order_code = customer_name[0].upper() + product_name[0].upper() + str(quantity)

# Display a readable summary.
print("\nSALES QUOTE & ORDER SUMMARY")
print("---------------------------")
print(f"Order code: {order_code}")
print(f"Customer: {customer_name}")
print(f"Product: {product_name}")
print(f"Unit price: {unit_price:.2f}")
print(f"Quantity: {quantity}")
print(f"Subtotal: {subtotal:.2f}")
print(f"Discount ({discount_pct:.2f}%): {discount_amount:.2f}")
print(f"Discounted subtotal: {discounted_subtotal:.2f}")
print(f"Tax ({tax_pct:.2f}%): {tax_amount:.2f}")
print(f"Final total: {final_total:.2f}")
print(f"Large order threshold: {large_order_threshold:.2f}")
print(f"Is large order: {is_large_order}")
