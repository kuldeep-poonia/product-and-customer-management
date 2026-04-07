# ShopIQ — Scanner Testing

## Supported Barcode Formats

QR Code, EAN-13, EAN-8, Code-128, Code-39, UPC-A, UPC-E, ITF, Data Matrix

## Testing Checklist

### Basic Scan
- [ ] Point camera at EAN-13 barcode on a product packet
- [ ] App vibrates and product name appears within 1 second
- [ ] Scanning same barcode again within 500ms does not add a duplicate

### Flashlight
- [ ] Tap torch icon — flash turns on
- [ ] Tap again — flash turns off
- [ ] Flash state resets when scanner screen is closed

### Product Lookup
- [ ] Scan a barcode that exists in the product list → product is added to cart
- [ ] Scan a barcode not in the product list → "Product not found" message appears
- [ ] Manual barcode input field accepts the same codes as the camera

### Error Cases
- [ ] Damaged barcode → no crash, soft error message shown
- [ ] Very low light (no flash) → graceful degradation, not a crash
- [ ] Covering the camera completely → no crash

### Scan History
- [ ] Last 20 scanned barcodes visible in scan history tab
- [ ] Each entry shows barcode, product name (if found), timestamp

## Device Testing Matrix

Test on at least one device from each tier:

| Tier | Example | RAM |
|------|---------|-----|
| Low | Redmi 9A | 2GB |
| Mid | Redmi Note 12 | 4GB |
| High | Samsung M34 | 6GB |

Camera autofocus speed varies significantly across these. The 500ms debounce
prevents double-scans on all tiers without feeling sluggish on the high tier.
