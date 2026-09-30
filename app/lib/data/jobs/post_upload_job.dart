import '../db/app_database.dart';
import '../db/tables.dart';
import '../social/social_repository.dart';
import 'job_runner.dart';

/// Sends a card published to the community (see [SocialRepository.queue]).
class PostUploadHandler implements JobHandler {
  PostUploadHandler(this._social);

  final SocialRepository _social;

  @override
  JobKind get kind => JobKind.postUpload;

  @override
  Future<JobOutcome> run(JobRow job) async {
    await _social.upload(job.subjectId);
    return const JobDone();
  }

  /// Still on the phone: the person sees it failed and may try again.
  @override
  Future<void> giveUp(JobRow job) => _social.fail(job.subjectId, 'unavailable');
}
