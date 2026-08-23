const String projGithubUrl = 'https://github.com/zrurf/Punklorde';

// 构建信息（通过 --dart-define 注入，未注入时回退为 unknown）
const String buildDate = String.fromEnvironment(
  'BUILD_DATE',
  defaultValue: 'unknown',
);
const String gitCommit = String.fromEnvironment(
  'GIT_COMMIT',
  defaultValue: 'unknown',
);
