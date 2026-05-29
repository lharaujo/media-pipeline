import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:media_pipeline_app/src/pipeline_models.dart';
import 'package:media_pipeline_app/src/pipeline_runner.dart';

Future<File> _createReaderScript(Directory root) async {
  final script = File('${root.path}/read_stdin.sh');
  await script.writeAsString('''
#!/usr/bin/env bash
set -euo pipefail

typed=""
if ! IFS= read -r typed; then
  typed=""
fi

echo "typed=\${typed:-<empty>}"
''');
  return script;
}

void main() {
  test('runner passes configured stdin text to child processes', () async {
    final tempRoot = await Directory.systemTemp.createTemp(
      'pipeline-runner-stdin-',
    );
    addTearDown(() async {
      if (await tempRoot.exists()) {
        await tempRoot.delete(recursive: true);
      }
    });

    final script = await _createReaderScript(tempRoot);
    final runner = PipelineRunner(workingDirectory: tempRoot.path);
    final step = PipelineStep(
      id: 'stdin-confirm',
      title: 'stdin confirm',
      description: 'reads stdin',
      risk: PipelineRisk.confirmRequired,
      command: PipelineCommand('bash', [
        script.path,
      ], stdinText: 'MOVE TAKEOUT DUPLICATES\n'),
    );

    final result = await runner.run(
      step,
      const PipelineSettings(hdPath: '/tmp', reportDir: '/tmp'),
    );

    expect(result.succeeded, isTrue);
    expect(result.output, contains('typed=MOVE TAKEOUT DUPLICATES'));
  });

  test('runner closes stdin when no stdin text is configured', () async {
    final tempRoot = await Directory.systemTemp.createTemp(
      'pipeline-runner-stdin-empty-',
    );
    addTearDown(() async {
      if (await tempRoot.exists()) {
        await tempRoot.delete(recursive: true);
      }
    });

    final script = await _createReaderScript(tempRoot);
    final runner = PipelineRunner(workingDirectory: tempRoot.path);
    final step = PipelineStep(
      id: 'stdin-empty',
      title: 'stdin empty',
      description: 'reads stdin',
      risk: PipelineRisk.safe,
      command: PipelineCommand('bash', [script.path]),
    );

    final result = await runner.run(
      step,
      const PipelineSettings(hdPath: '/tmp', reportDir: '/tmp'),
    );

    expect(result.succeeded, isTrue);
    expect(result.output, contains('typed=<empty>'));
  });
}
