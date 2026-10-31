extends RefCounted

# Compact short scale, with a Portuguese decimal comma. Truncate rather
# than round up so an unaffordable price never appears affordable.
static func compact(value: int) -> String:
	var magnitude: float = absf(float(value))
	var suffixes: Array[String] = ["", "K", "M", "B", "T"]
	var index: int = 0
	while magnitude >= 1000.0 and index < suffixes.size() - 1:
		magnitude /= 1000.0
		index += 1
	if index == 0:
		return str(value)
	var amount: float = floorf(magnitude * 10.0) / 10.0
	var digits: String = ("%.1f" % amount).trim_suffix(".0").replace(".", ",")
	return ("-" if value < 0 else "") + digits + suffixes[index]
