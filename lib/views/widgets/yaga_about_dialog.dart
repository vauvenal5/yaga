import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_svg/svg.dart';
import 'package:markdown/markdown.dart' as mk;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:yaga/utils/service_locator.dart';

class YagaAboutDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AboutDialog(
      applicationVersion: "v${getIt.get<PackageInfo>().version}",
      applicationIcon: SvgPicture.asset(
        "assets/icon/icon.svg",
        semanticsLabel: 'Yaga Logo',
        width: 56,
      ),
      children: [
        FutureBuilder(
          future: DefaultAssetBundle.of(context).loadString("assets/news.md"),
          builder: (context, snapshot) {
            final sc = ScrollController();
            return SizedBox(
              height: 300,
              width: 400,
              child: Scrollbar(
                thumbVisibility: true,
                controller: sc,
                child: Markdown(
                  padding: const EdgeInsets.fromLTRB(0.0, 0.0, 5.0, 0.0),
                  data: snapshot.data?.toString() ?? "",
                  shrinkWrap: true,
                  controller: sc,
                  extensionSet: mk.ExtensionSet(
                    mk.ExtensionSet.gitHubFlavored.blockSyntaxes,
                    [
                      mk.EmojiSyntax(),
                      ...mk.ExtensionSet.gitHubFlavored.inlineSyntaxes
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        Align(
          alignment: Alignment.topLeft,
          child: TextButton.icon(
            onPressed: () =>
                launchUrlString("https://vauvenal5.github.io/yaga-docs/"),
            icon: const Icon(Icons.book_outlined),
            label: const Text("Read the docs"),
          ),
        ),
        Align(
          alignment: Alignment.topLeft,
          child: TextButton.icon(
            onPressed: () => launchUrlString(
              "https://vauvenal5.github.io/yaga-docs/privacy/",
            ),
            icon: const Icon(Icons.policy_outlined),
            label: const Text("Privacy Policy"),
          ),
        ),
        Align(
          alignment: Alignment.topLeft,
          child: TextButton.icon(
            onPressed: () =>
                launchUrlString("https://github.com/vauvenal5/yaga/issues"),
            icon: const Icon(Icons.bug_report_outlined),
            label: const Text("Report a bug"),
          ),
        ),
      ],
    );
  }
}
