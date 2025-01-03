module.exports = async ({github, context, core}) => {
  const owner = context.repo.owner
  const repo = context.repo.repo
  
  const status = context.job.status
  const sha = context.sha
  const environment = 'production'
  
  const emoji = status === 'success' ? '✅' : '❌'
  const color = status === 'success' ? '#36a64f' : '#dc3545'
  
  const message = {
    owner,
    repo,
    issue_number: context.issue.number,
    body: `${emoji} Deployment to ${environment} ${status}\n\nCommit: ${sha}\nWorkflow: ${context.workflow}\nJob: ${context.job}`
  }
  
  if (context.issue.number) {
    await github.rest.issues.createComment(message)
  }
  
  // Create deployment status
  const deployment = await github.rest.repos.createDeployment({
    owner,
    repo,
    ref: context.ref,
    environment,
    auto_merge: false
  })
  
  await github.rest.repos.createDeploymentStatus({
    owner,
    repo,
    deployment_id: deployment.data.id,
    state: status === 'success' ? 'success' : 'failure',
    environment
  })
}