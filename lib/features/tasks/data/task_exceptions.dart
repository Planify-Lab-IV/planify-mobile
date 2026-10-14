sealed class TasksException implements Exception {
  const TasksException();
}

class TaskNotFoundException extends TasksException {
  const TaskNotFoundException();
}

class TaskAuthorizationException extends TasksException {
  const TaskAuthorizationException();
}

class TaskValidationException extends TasksException {
  const TaskValidationException();
}

class TaskOperationException extends TasksException {
  const TaskOperationException();
}

class NetworkTaskException extends TasksException {
  const NetworkTaskException();
}

class InvalidTaskResponseException extends TasksException {
  const InvalidTaskResponseException();
}
