from rest_framework import serializers
from django.core.validators import MinLengthValidator, MaxLengthValidator
import re

# === DCYN (Deconstructed Yes/No) Logic Library ===
class DCYNValidator:
    """
    Binary Yes/No logic library that deconstructs complex JSON into clean data flows.
    """
    @staticmethod
    def is_valid_email(email):
        # Returns True/False (Yes/No) if the email format is valid
        pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        return re.match(pattern, email) is not None

    @staticmethod
    def is_valid_phone(phone):
        # Returns True/False (Yes/No) if the phone number is valid (basic check)
        return phone.isdigit() and len(phone) == 10

    @staticmethod
    def is_adult(age):
        # Returns True/False (Yes/No) if the age confirms adult status
        return age >= 18

# === Serializer ===
class StudentOnboardingSerializer(serializers.Serializer):
    """
    Model serializer with exact field validation limits to eliminate human judgment.
    """
    student_name = serializers.CharField(
        max_length=100,
        validators=[MinLengthValidator(3), MaxLengthValidator(100)]
    )
    parent_email = serializers.EmailField(
        max_length=255,
        validators=[DCYNValidator.is_valid_email]
    )
    parent_phone = serializers.CharField(
        max_length=10,
        validators=[DCYNValidator.is_valid_phone]
    )
    student_age = serializers.IntegerField(
        min_value=1,
        max_value=18,
        validators=[DCYNValidator.is_adult]  # Enforces binary Yes/No on age
    )
    consent_given = serializers.BooleanField(required=True)

    def validate_student_name(self, value):
        # Custom field-level validation
        if not DCYNValidator.is_valid_email(self.initial_data.get('parent_email')):
            raise serializers.ValidationError("Parent email must be valid.")
        return value

    def validate(self, data):
        # Object-level validation logic for cross-field dependencies
        if not data['consent_given']:
            raise serializers.ValidationError("Parental consent is mandatory.")
        return data