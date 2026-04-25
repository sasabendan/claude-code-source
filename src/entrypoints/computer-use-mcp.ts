import '../dev/installRuntimeGlobals.js'

process.env.COMPUTER_USE_INPUT_NODE_PATH =
  '/Users/jennyhu/claude-code-source/deps/@ant/computer-use-input/prebuilds/computer-use-input.node'
process.env.COMPUTER_USE_SWIFT_NODE_PATH =
  '/Users/jennyhu/claude-code-source/deps/@ant/computer-use-swift/prebuilds/computer_use.node'

const { runComputerUseMcpServer } = await import('../utils/computerUse/mcpServer.js')
await runComputerUseMcpServer()
