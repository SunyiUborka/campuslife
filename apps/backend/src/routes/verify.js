import { prisma } from "../db.js"

export default async function verifyRoutes(fastify) {
  fastify.get('/verify', {
    schema: {
      querystring: {
        type: 'object',
        required: ['token'],
        properties: {
          token: { type: 'string' }
        }
      }
    }
  }, async (request, reply) => {
    const { token } = request.query

    try {
      const user = await prisma.user.findUnique({
        where: { verificationToken: token }
      })

      if (!user)
        return reply.status(404).send({ error: 'Invalid or expired token' })

      await prisma.user.update({
        where: { id: user.id },
        data: {
          isVerified: true,
          verificationToken: null
        }
      })

      const baseUrl = process.env.BASE_URL || 'https://campuslife.social'
      return reply.redirect(`${baseUrl}/login?verified=true`)

    } catch (error) {
      fastify.log.error(error)
      return reply.status(500).send({ error: 'Internal server error' })
    }
  })
}