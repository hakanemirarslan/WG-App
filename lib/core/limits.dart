import 'package:flutter/services.dart';

/// Text length limits. They mirror the check constraints in `supabase/schema.sql`
/// (the database enforces them; the fields stop typing at the limit so a user
/// never runs into a server error).
const maxDisplayNameLength = 50;
const maxGroupNameLength = 60;
const maxProductNameLength = 60;
const maxNoteLength = 200;
const maxDescriptionLength = 200;

/// Input formatter that stops typing at [maxLength] characters, without the
/// character counter that `TextField.maxLength` would show.
List<TextInputFormatter> limitTo(int maxLength) => [LengthLimitingTextInputFormatter(maxLength)];
