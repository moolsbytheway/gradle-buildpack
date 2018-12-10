#!/usr/bin/env bash

handle_gradle_errors() {
  local log_file="$1"

  local header="Failed to run Gradle!"

  local previousVersion="You can also try reverting to the previous version of the buildpack by running:
$ scalingo env-set BUILDPACK_URL=https://github.com/Scalingo/gradle-buildpack#previous-version"

  local footer="Thanks,
Scalingo"

  if grep -qi "Task 'stage' not found in root project" "$log_file"; then
    mcount "error.no-stage-task"
    error "${header}
It looks like your project does not contain a 'stage' task, which Scalingo needs in order
to build your app. Our documentation article on preparing a Gradle application for Scalingo
describes how to create this task:
http://doc.scalingo.com/languages/java/gradle.html

If you're stilling having trouble, do not hesitate to contact us at support@scalingo.com.

${footer}"
  elif grep -qi "Could not find or load main class org.gradle.wrapper.GradleWrapperMain" "$log_file"; then
    mcount "error.no-gradle-jar"
    error "${header}
It looks like you don't have a gradle-wrapper.jar file checked into your Git repo.
Scalingo needs this JAR file in order to run Gradle.  Our documentation article on preparing
a Gradle application for Scalingo describes how to fix this:
http://doc.scalingo.com/languages/java/gradle.html

If you're stilling having trouble, do not hesitate to contact us at support@scalingo.com.

${footer}"
  else
    mcount "error.unknown"
    error "${header}
We're sorry this build is failing. If you can't find the issue in application
code, feel free to contact our support team at support@scalingo.com.
${previousVersion}

${footer}"
  fi
}
