"""Collect MSVC model coverage with Microsoft's native coverage tool; require 80%."""
import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import xml.etree.ElementTree as ET


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--build', type=Path, required=True)
    parser.add_argument('--config', required=True)
    parser.add_argument('--reports', type=Path, required=True)
    parser.add_argument('--source', type=Path, required=True)
    parser.add_argument('--executable', type=Path, required=True)
    parser.add_argument('--collector', required=True)
    parser.add_argument('--ctest', required=True)
    args = parser.parse_args()
    if args.config.lower() != 'debug':
        sys.exit('Use the Debug configuration for native model line coverage')
    output = args.reports.resolve()
    output.mkdir(exist_ok=True)
    report = output / 'model.cobertura.xml'
    junit = output.parent / 'model-tests.xml'
    for stale in (report, junit):
        stale.unlink(missing_ok=True)
    configuration = ET.Element('Configuration')
    coverage = ET.SubElement(configuration, 'CodeCoverage')
    modules = ET.SubElement(coverage, 'ModulePaths')
    directories = ET.SubElement(modules, 'IncludeDirectories')
    ET.SubElement(directories, 'Directory').text = str(args.executable.resolve().parent)
    include = ET.SubElement(modules, 'Include')
    ET.SubElement(include, 'ModulePath').text = re.escape(str(args.executable.resolve()))
    sources = ET.SubElement(coverage, 'Sources')
    include = ET.SubElement(sources, 'Include')
    ET.SubElement(include, 'Source').text = r'.*[\\/]model\.(cpp|h)$'
    ET.SubElement(coverage, 'EnableStaticNativeInstrumentation').text = 'True'
    ET.SubElement(coverage, 'EnableDynamicNativeInstrumentation').text = 'False'
    ET.SubElement(coverage, 'EnableStaticNativeInstrumentationRestore').text = 'True'
    settings = output / 'coverage.config'
    ET.ElementTree(configuration).write(settings, encoding='utf-8', xml_declaration=True)
    environment = os.environ.copy()
    environment['DOTNET_COVERAGE_TELEMETRY_OPTOUT'] = '1'
    subprocess.run([args.collector, 'collect', '--settings', str(settings),
                    '--output', str(report), '--output-format', 'cobertura', '--nologo',
                    args.ctest, '--test-dir', str(args.build), '-C', args.config,
                    '-R', '^qshopper_tests$', '--output-on-failure'],
                   env=environment, check=True)
    # Require fresh QTest results even if the collector doesn't propagate a child exit code.
    results = ET.parse(junit).getroot()
    suites = [results] if results.tag == 'testsuite' else list(results.iter('testsuite'))
    if not suites or any(int(s.get('failures', 0)) or int(s.get('errors', 0)) for s in suites):
        sys.exit('Model QTest suite failed')
    source = args.source.resolve()
    files = {os.path.normcase(str(source / name)): {} for name in ('model.cpp', 'model.h')}
    root = ET.parse(report).getroot()
    for entry in root.iter('class'):
        path = Path(entry.get('filename', ''))
        if not path.is_absolute():
            path = source / path
        key = os.path.normcase(str(path.resolve()))
        if key not in files:
            continue
        for line in entry.findall('./lines/line'):
            number = int(line.get('number'))
            files[key][number] = max(files[key].get(number, 0), int(line.get('hits')))
    rows = []
    for path, counts in files.items():
        if not counts:
            sys.exit(f'Missing native coverage data for {Path(path).name}; check Debug PDBs')
        rows.append({'file': Path(path).name, 'covered': sum(n > 0 for n in counts.values()),
                     'lines': len(counts), 'uncovered': sorted(n for n, hits in counts.items() if not hits)})
    covered = sum(row['covered'] for row in rows)
    total = sum(row['lines'] for row in rows)
    percent = 100 * covered / total
    summary = {'covered': covered, 'lines': total, 'percent': percent, 'minimum': 80, 'files': rows}
    (output / 'summary.json').write_text(json.dumps(summary, indent=2) + '\n', encoding='utf-8')
    table = ['# Model line coverage (MSVC)', '', '| File | Covered / executable lines | Coverage |',
             '| --- | ---: | ---: |']
    for row in rows:
        table.append(f'| {row["file"]} | {row["covered"]} / {row["lines"]} | {100 * row["covered"] / row["lines"]:.2f}% |')
    table += [f'| **Total** | **{covered} / {total}** | **{percent:.2f}%** |', '',
              'Only model.cpp and model.h count. Required aggregate coverage: 80%.', '']
    (output / 'summary.md').write_text('\n'.join(table), encoding='utf-8')
    print('\n'.join(table))
    if percent < 80:
        sys.exit('Model line coverage is below 80%')


if __name__ == '__main__':
    main()
