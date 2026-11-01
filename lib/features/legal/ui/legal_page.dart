import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error_view.dart';
import '../../../core/layout.dart';
import '../../../l10n/app_localizations.dart';

/// The two legal texts. Their content lives in Markdown files under `assets/legal/`
/// so they can be edited without touching code; the text is German (the site is
/// operated in Germany), the page title follows the app language.
enum LegalDocument {
  privacy('assets/legal/datenschutz.md'),
  imprint('assets/legal/impressum.md');

  const LegalDocument(this.asset);
  final String asset;
}

/// Shows a legal text. Reachable without signing in (router.dart), linked from the
/// login and signup forms and from the settings.
class LegalPage extends StatelessWidget {
  const LegalPage({super.key, required this.document});

  final LegalDocument document;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = switch (document) {
      LegalDocument.privacy => l10n.privacyPolicyTitle,
      LegalDocument.imprint => l10n.imprintTitle,
    };
    return Scaffold(
      appBar: AppBar(
        // Opened by a link (push) there is a page to go back to; opened directly by
        // URL there is not, so go to the start page instead.
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/')),
        title: Text(title),
      ),
      body: FutureBuilder<String>(
        future: rootBundle.loadString(document.asset),
        builder: (context, snapshot) {
          if (snapshot.hasError) return ErrorView(error: snapshot.error);
          final text = snapshot.data;
          if (text == null) return const LoadingView();
          return ContentWidth(
            maxWidth: 760,
            child: Markdown(data: text, selectable: true, padding: const EdgeInsets.all(24)),
          );
        },
      ),
    );
  }
}

/// "Datenschutz · Impressum" links, shown under the login and signup forms and in
/// the settings.
class LegalLinks extends StatelessWidget {
  const LegalLinks({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final style = TextButton.styleFrom(
      foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
      textStyle: Theme.of(context).textTheme.bodySmall,
    );
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 4,
      children: [
        TextButton(
          style: style,
          onPressed: () => context.push('/datenschutz'),
          child: Text(l10n.privacyPolicyTitle),
        ),
        TextButton(
          style: style,
          onPressed: () => context.push('/impressum'),
          child: Text(l10n.imprintTitle),
        ),
      ],
    );
  }
}
