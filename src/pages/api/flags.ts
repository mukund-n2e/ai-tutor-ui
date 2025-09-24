export default function handler(_req, res){res.status(200).json({beta:true,moves:['Understand','Draft','Polish'],ts:new Date().toISOString()});}
export const config = { api: { bodyParser: true } };
