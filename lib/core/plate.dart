final _validPlatePattern = RegExp(
  r'^(?:[A-Z]{4}[0-9]{2}|[A-Z]{3}[0-9]{2}|[A-Z]{2}[0-9]{3}[A-Z]{2}|[A-Z]{3}[0-9]{3})$',
);

String normalizePlate(String input) =>
    input.toUpperCase().replaceAll(' ', '').replaceAll('-', '');

bool isValidPlate(String input) =>
    _validPlatePattern.hasMatch(normalizePlate(input));
