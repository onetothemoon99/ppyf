// สร้างรูปเหรียญตรา Roblox (512x512) เป็น SVG แล้วเรนเดอร์ PNG ด้วย Chrome headless
// ใช้: node art/badges/generate.js
// เพิ่มตรา: เพิ่มขั้นใน TIERS (สีขอบ) แล้วเพิ่มแถวใน BADGES พร้อมฟังก์ชันวาดไอคอน

const fs = require("fs");
const path = require("path");
const { execFileSync } = require("child_process");

const OUT = __dirname;
const CHROME = "C:/Program Files/Google/Chrome/Application/chrome.exe";
const INK = "#3b2a20";
const FONT = "'Arial Black','Segoe UI Black',sans-serif";

const TIERS = {
	1: { light: "#f6c08f", mid: "#c9743a", dark: "#7d3f1b", ribbon: "#b5602a", stars: 1 }, // ทองแดง
	2: { light: "#ffffff", mid: "#bcc7d6", dark: "#6f7d92", ribbon: "#7f8ea6", stars: 2 }, // เงิน
	3: { light: "#fff3a8", mid: "#ffc62e", dark: "#b8730a", ribbon: "#e0940f", stars: 3 }, // ทอง
	4: { light: "#eafdff", mid: "#6fd6f7", dark: "#2377bd", ribbon: "#2a93d6", stars: 4 }, // เพชร
	welcome: { light: "#ffe6f0", mid: "#ff94bb", dark: "#c94f86", ribbon: "#ee5f98", stars: 0, hearts: 3 }, // ตราพิเศษ ยินดีต้อนรับ
};

// ---------- ชิ้นส่วนพื้นฐาน ----------
function star(cx, cy, r, fill) {
	const pts = [];
	for (let i = 0; i < 10; i++) {
		const a = -Math.PI / 2 + (i * Math.PI) / 5;
		const rr = i % 2 ? r * 0.48 : r;
		pts.push(`${(cx + rr * Math.cos(a)).toFixed(1)},${(cy + rr * Math.sin(a)).toFixed(1)}`);
	}
	return `<polygon points="${pts.join(" ")}" fill="${fill}" stroke="${INK}" stroke-width="4" stroke-linejoin="round"/>`;
}

function leaf(x, y, len, w, deg, fill = "url(#leaf)") {
	return `<g transform="translate(${x} ${y}) rotate(${deg})">
		<path d="M0,0 C${w},${-len * 0.25} ${w * 0.85},${-len * 0.8} 0,${-len} C${-w * 0.85},${-len * 0.8} ${-w},${-len * 0.25} 0,0Z"
			fill="${fill}" stroke="${INK}" stroke-width="8" stroke-linejoin="round"/>
		<path d="M0,${-len * 0.12} L0,${-len * 0.72}" stroke="#3f9a3c" stroke-width="6" stroke-linecap="round" fill="none"/>
	</g>`;
}

function stem(d) {
	return `<path d="${d}" fill="none" stroke="${INK}" stroke-width="26" stroke-linecap="round"/>
		<path d="${d}" fill="none" stroke="#58c04e" stroke-width="12" stroke-linecap="round"/>`;
}

function soil() {
	return `<path d="M128,348 Q256,276 384,348 Q256,382 128,348Z" fill="#8a5a35" stroke="${INK}" stroke-width="9" stroke-linejoin="round"/>
		<path d="M170,334 Q256,298 330,330" fill="none" stroke="#b07a4c" stroke-width="10" stroke-linecap="round"/>`;
}

function heart(cx, cy, r, fill) {
	return `<path transform="translate(${cx} ${cy}) scale(${r / 20})" d="M0,18 C-30,-4 -20,-24 -8,-22 C-3,-21 0,-16 0,-13 C0,-16 3,-21 8,-22 C20,-24 30,-4 0,18Z"
		fill="${fill}" stroke="${INK}" stroke-width="${80 / r}" stroke-linejoin="round"/>`;
}

function bubble(x, y, r) {
	return `<circle cx="${x}" cy="${y}" r="${r}" fill="#ffffff66" stroke="#ffffff" stroke-width="5"/>
		<circle cx="${x - r * 0.3}" cy="${y - r * 0.3}" r="${r * 0.22}" fill="#fff"/>`;
}

// ไข่ จุดศูนย์กลาง x,y สูงประมาณ r*2.5
function egg(x, y, r, fill, shine = "#ffffffcc", deg = 0) {
	return `<g transform="translate(${x} ${y}) rotate(${deg})">
		<path d="M0,${-r * 1.3} C${r * 0.75},${-r * 1.3} ${r},${-r * 0.1} ${r},${r * 0.28} C${r},${r * 0.9} ${r * 0.55},${r * 1.2} 0,${r * 1.2} C${-r * 0.55},${r * 1.2} ${-r},${r * 0.9} ${-r},${r * 0.28} C${-r},${-r * 0.1} ${-r * 0.75},${-r * 1.3} 0,${-r * 1.3}Z"
			fill="${fill}" stroke="${INK}" stroke-width="9" stroke-linejoin="round"/>
		<ellipse cx="${-r * 0.36}" cy="${-r * 0.42}" rx="${r * 0.17}" ry="${r * 0.32}" fill="${shine}" transform="rotate(16 ${-r * 0.36} ${-r * 0.42})"/>
	</g>`;
}

// รังฟางด้านหน้า วางทับก้นไข่
function nest(y = 330) {
	let straw = "";
	for (let i = 0; i < 15; i++) {
		const x = 128 + i * 18.2;
		straw += `<path d="M${x},${y + 12} L${x + (i % 2 ? 26 : -22)},${y - 22}" stroke="${i % 3 ? "#f7d774" : "#e0a93a"}" stroke-width="9" stroke-linecap="round"/>`;
	}
	return `<path d="M108,${y} Q256,${y - 44} 404,${y} Q392,${y + 62} 256,${y + 62} Q120,${y + 62} 108,${y}Z" fill="#d99a3a" stroke="${INK}" stroke-width="10" stroke-linejoin="round"/>${straw}`;
}

function sparkle(x, y, r, fill = "#fff") {
	return `<path d="M${x},${y - r} Q${x + r * 0.14},${y - r * 0.14} ${x + r},${y} Q${x + r * 0.14},${y + r * 0.14} ${x},${y + r} Q${x - r * 0.14},${y + r * 0.14} ${x - r},${y} Q${x - r * 0.14},${y - r * 0.14} ${x},${y - r}Z" fill="${fill}"/>`;
}

// ดาวใหญ่ขอบหนา ใช้กับหมวดเลเวล
function bigStar(cx, cy, r, fill) {
	const pts = [];
	for (let i = 0; i < 10; i++) {
		const a = -Math.PI / 2 + (i * Math.PI) / 5;
		const rr = i % 2 ? r * 0.52 : r;
		pts.push(`${(cx + rr * Math.cos(a)).toFixed(1)},${(cy + rr * Math.sin(a)).toFixed(1)}`);
	}
	return `<polygon points="${pts.join(" ")}" fill="${fill}" stroke="${INK}" stroke-width="10" stroke-linejoin="round"/>`;
}

// ลูกศรชี้ขึ้น ปลายอยู่ที่ x,y
function upArrow(x, y, w, h, fill) {
	const hw = w / 2;
	const sw = w * 0.24;
	const head = h * 0.5;
	return `<path d="M${x},${y} L${x + hw},${y + head} H${x + sw} V${y + h} H${x - sw} V${y + head} H${x - hw}Z"
		fill="${fill}" stroke="${INK}" stroke-width="10" stroke-linejoin="round"/>`;
}

// ปลาหันขวา จุดศูนย์กลาง 0,0 ยาวประมาณ 340
function fish(x, y, scale, deg, c) {
	return `<g transform="translate(${x} ${y}) rotate(${deg}) scale(${scale})">
		<path d="M-96,0 L-178,-62 Q-146,0 -178,62Z" fill="${c.fin}" stroke="${INK}" stroke-width="10" stroke-linejoin="round"/>
		<path d="M-40,-58 Q0,-122 58,-62Z" fill="${c.fin}" stroke="${INK}" stroke-width="10" stroke-linejoin="round"/>
		<path d="M-22,58 Q6,104 44,58Z" fill="${c.fin}" stroke="${INK}" stroke-width="10" stroke-linejoin="round"/>
		<path d="M-122,0 C-66,-82 72,-84 136,0 C72,84 -66,82 -122,0Z" fill="${c.body}" stroke="${INK}" stroke-width="10" stroke-linejoin="round"/>
		<path d="M-96,20 C-40,62 62,62 118,18 C60,36 -40,38 -96,20Z" fill="${c.belly}"/>
		<path d="M48,-44 Q24,0 48,44" fill="none" stroke="${INK}" stroke-width="8" stroke-linecap="round"/>
		<path d="M-4,-8 Q-34,16 -6,32 Q2,12 -4,-8Z" fill="${c.fin}" stroke="${INK}" stroke-width="8" stroke-linejoin="round"/>
		<circle cx="84" cy="-14" r="20" fill="#fff" stroke="${INK}" stroke-width="7"/>
		<circle cx="90" cy="-13" r="10" fill="${INK}"/>
		<circle cx="94" cy="-18" r="4" fill="#fff"/>
		<path d="M114,20 Q124,24 130,14" fill="none" stroke="${INK}" stroke-width="7" stroke-linecap="round"/>
	</g>`;
}

// ---------- ไอคอนแต่ละตรา ----------
const ICONS = {
	plant1: () => `${stem("M256,330 C256,290 256,260 256,214")}
		${leaf(256, 226, 124, 62, -56)}${leaf(256, 226, 124, 62, 56)}${soil()}`,
	plant2: () => `${stem("M256,330 C256,270 256,210 256,150")}
		${leaf(256, 282, 112, 54, -72)}${leaf(256, 282, 112, 54, 72)}
		${leaf(256, 214, 104, 50, -56)}${leaf(256, 214, 104, 50, 56)}
		${leaf(256, 170, 92, 46, 0)}${soil()}`,
	plant3: () => {
		let petals = "";
		for (let i = 0; i < 14; i++) {
			petals += `<path transform="rotate(${(i * 360) / 14} 256 176)" d="M256,176 C226,136 234,96 256,84 C278,96 286,136 256,176Z"
				fill="#ffd21f" stroke="${INK}" stroke-width="7" stroke-linejoin="round"/>`;
		}
		return `${stem("M256,330 C256,290 256,250 256,190")}
			${leaf(256, 300, 106, 50, -66)}${leaf(256, 300, 106, 50, 66)}
			${petals}<circle cx="256" cy="176" r="48" fill="#7a4620" stroke="${INK}" stroke-width="8"/>
			<circle cx="256" cy="176" r="28" fill="#5a3216"/>
			<circle cx="243" cy="162" r="7" fill="#a86a35"/>${soil()}`;
	},
	plant4: () => {
		const blob = (x, y, r, c) => `<circle cx="${x}" cy="${y}" r="${r}" fill="${c}" stroke="${INK}" stroke-width="9"/>`;
		const fruit = (x, y) => `<circle cx="${x}" cy="${y}" r="17" fill="#ff5f5f" stroke="${INK}" stroke-width="6"/><circle cx="${x - 5}" cy="${y - 6}" r="4" fill="#fff"/>`;
		return `<path d="M226,340 C236,290 232,250 226,206 L286,206 C280,250 276,290 286,340Z" fill="#9a6235" stroke="${INK}" stroke-width="10" stroke-linejoin="round"/>
			${blob(164, 206, 62, "#58c04e")}${blob(348, 206, 62, "#58c04e")}${blob(204, 134, 66, "#6fd05a")}${blob(310, 134, 66, "#6fd05a")}
			${blob(256, 192, 88, "#7fdc62")}
			<ellipse cx="226" cy="150" rx="34" ry="18" fill="#c5f59a"/>
			${fruit(180, 224)}${fruit(330, 226)}${fruit(256, 244)}${fruit(292, 148)}${fruit(208, 104)}${soil()}`;
	},
	level1: () => `${upArrow(256, 92, 190, 250, "url(#up)")}`,
	level2: () => `${upArrow(176, 150, 130, 190, "url(#up)")}${upArrow(336, 150, 130, 190, "url(#up)")}${upArrow(256, 84, 160, 256, "url(#up)")}`,
	level3: () => `${bigStar(256, 226, 124, "url(#gold)")}
		<g transform="translate(256 96)">
			<path d="M-72,44 L-86,-26 L-40,8 L0,-48 L40,8 L86,-26 L72,44Z" fill="url(#gold)" stroke="${INK}" stroke-width="10" stroke-linejoin="round"/>
			<circle cx="0" cy="16" r="12" fill="#ff5f8f" stroke="${INK}" stroke-width="6"/>
		</g>`,
	time1: () => {
		let ticks = "";
		for (let i = 0; i < 12; i++) {
			ticks += `<path transform="rotate(${i * 30} 256 226)" d="M256,${i % 3 ? 130 : 126} V${i % 3 ? 144 : 156}" stroke="${INK}" stroke-width="${i % 3 ? 7 : 11}" stroke-linecap="round"/>`;
		}
		return `<path d="M160,322 L134,356 M352,322 L378,356" stroke="${INK}" stroke-width="16" stroke-linecap="round"/>
			<circle cx="148" cy="118" r="44" fill="url(#gold)" stroke="${INK}" stroke-width="10"/>
			<circle cx="364" cy="118" r="44" fill="url(#gold)" stroke="${INK}" stroke-width="10"/>
			<circle cx="256" cy="226" r="122" fill="#ff7a6b" stroke="${INK}" stroke-width="10"/>
			<circle cx="256" cy="226" r="102" fill="#fff8ea" stroke="${INK}" stroke-width="8"/>
			${ticks}
			<path d="M256,226 V158 M256,226 L306,256" stroke="${INK}" stroke-width="13" stroke-linecap="round"/>
			<circle cx="256" cy="226" r="11" fill="#ff5f8f" stroke="${INK}" stroke-width="6"/>`;
	},
	time2: () => `<path d="M186,120 C186,196 226,206 240,226 C226,246 186,256 186,332 H326 C326,256 286,246 272,226 C286,206 326,196 326,120Z" fill="#dff6ff" stroke="${INK}" stroke-width="10" stroke-linejoin="round"/>
		<path d="M204,158 H308 C302,196 272,204 256,222 C240,204 210,196 204,158Z" fill="#ffd25e"/>
		<path d="M204,318 C214,282 238,270 256,258 C274,270 298,282 308,318Z" fill="#ffd25e"/>
		<path d="M256,222 V262" stroke="#ffd25e" stroke-width="7" stroke-linecap="round"/>
		<rect x="160" y="88" width="192" height="36" rx="16" fill="#b5602a" stroke="${INK}" stroke-width="10"/>
		<rect x="160" y="328" width="192" height="36" rx="16" fill="#b5602a" stroke="${INK}" stroke-width="10"/>`,
	egg1: () => `${egg(256, 228, 76, "#fff6e6")}${nest(306)}`,
	egg2: () => `${egg(176, 244, 56, "#ffe9c9", "#ffffffcc", -12)}${egg(336, 244, 56, "#fff6e6", "#ffffffcc", 12)}${egg(256, 208, 68, "#fff6e6")}${nest(306)}`,
	egg3: () => `${egg(256, 208, 92, "url(#gold)", "#fffbe0")}${nest(306)}`,
	fish3: () => `${fish(240, 250, 0.95, -8, { body: "#ffcc33", belly: "#fff2ad", fin: "#f28c1e" })}
		<g transform="translate(326 142) rotate(8)">
			<path d="M-54,34 L-64,-26 L-28,4 L0,-44 L28,4 L64,-26 L54,34Z" fill="url(#gold)" stroke="${INK}" stroke-width="9" stroke-linejoin="round"/>
			<circle cx="0" cy="10" r="10" fill="#ff5f8f" stroke="${INK}" stroke-width="5"/>
		</g>`,
	welcome: () => `
		<circle cx="146" cy="214" r="19" fill="#9a6a45" stroke="${INK}" stroke-width="9"/>
		<circle cx="366" cy="214" r="19" fill="#9a6a45" stroke="${INK}" stroke-width="9"/>
		<circle cx="146" cy="215" r="8" fill="#e6b58f"/><circle cx="366" cy="215" r="8" fill="#e6b58f"/>
		<ellipse cx="256" cy="250" rx="124" ry="96" fill="#a8744c" stroke="${INK}" stroke-width="10"/>
		<ellipse cx="256" cy="284" rx="100" ry="58" fill="#f4dcc2"/>
		<path d="M176,282 L136,272 M176,296 L134,300 M336,282 L376,272 M336,296 L378,300" fill="none" stroke="${INK}" stroke-width="6" stroke-linecap="round"/>
		<ellipse cx="184" cy="274" rx="20" ry="12" fill="#ff9db4" opacity=".8"/>
		<ellipse cx="328" cy="274" rx="20" ry="12" fill="#ff9db4" opacity=".8"/>
		<circle cx="210" cy="238" r="17" fill="${INK}"/><circle cx="216" cy="232" r="6" fill="#fff"/>
		<circle cx="302" cy="238" r="17" fill="${INK}"/><circle cx="308" cy="232" r="6" fill="#fff"/>
		<ellipse cx="256" cy="264" rx="18" ry="13" fill="${INK}"/><ellipse cx="250" cy="260" rx="5" ry="3" fill="#fff"/>
		<path d="M256,277 V288 M256,288 Q238,306 220,292 M256,288 Q274,306 292,292" fill="none" stroke="${INK}" stroke-width="7" stroke-linecap="round"/>
		<ellipse cx="256" cy="158" rx="138" ry="28" fill="#f5cf6b" stroke="${INK}" stroke-width="10"/>
		<path d="M184,156 Q188,86 256,84 Q324,86 328,156 Q256,178 184,156Z" fill="#fbdf8d" stroke="${INK}" stroke-width="10" stroke-linejoin="round"/>
		<path d="M185,132 Q256,152 327,132 L328,156 Q256,178 184,156Z" fill="#e8574a" stroke="${INK}" stroke-width="9" stroke-linejoin="round"/>
		<g transform="rotate(14 396 262)">
			<circle cx="396" cy="262" r="35" fill="#a8744c" stroke="${INK}" stroke-width="9"/>
			<ellipse cx="396" cy="272" rx="15" ry="12" fill="#f4dcc2"/>
			<circle cx="376" cy="248" r="7" fill="#f4dcc2"/><circle cx="396" cy="240" r="7" fill="#f4dcc2"/><circle cx="416" cy="248" r="7" fill="#f4dcc2"/>
		</g>`,
	fish1: () => `${fish(262, 228, 0.82, -6, { body: "#ff9f43", belly: "#ffe0b0", fin: "#ff6f3c" })}`,
	fish2: () => `${fish(248, 240, 0.92, -8, { body: "#4db8ff", belly: "#d5f2ff", fin: "#2384e8" })}`,
};

// ของที่วาดหลังไอคอน
const BEHIND = {
	welcome: () => {
		let rays = "";
		for (let i = 0; i < 12; i++) rays += `<path transform="rotate(${i * 30} 370 112)" d="M360,62 L370,30 L380,62Z" fill="#ffc62e"/>`;
		return `<g clip-path="url(#disc)">${rays}<circle cx="370" cy="112" r="44" fill="#ffd84f"/></g>`;
	},
};

// ของที่ไม่ใส่ขอบสติกเกอร์ (ฟองอากาศ)
const EXTRAS = {
	fish1: () => `${bubble(360, 128, 17)}${bubble(394, 176, 11)}`,
	fish2: () => `${bubble(384, 150, 21)}${bubble(350, 104, 14)}${bubble(148, 124, 15)}`,
	fish3: () => `${bubble(150, 120, 16)}${bubble(112, 176, 10)}${sparkle(208, 118, 18)}${sparkle(404, 250, 15)}`,
	level3: () => `${sparkle(112, 170, 22)}${sparkle(404, 176, 18)}${sparkle(392, 300, 14)}`,
	level2: () => `${sparkle(108, 150, 16)}${sparkle(404, 136, 14)}`,
	level1: () => `${sparkle(136, 170, 18)}${sparkle(374, 214, 14)}`,
	egg3: () => `${sparkle(136, 150, 26)}${sparkle(384, 128, 20)}${sparkle(400, 224, 14)}${sparkle(122, 240, 13)}`,
};

// ---------- ประกอบเหรียญ ----------
// รูปวาดเต็มวง (ตรายินดีต้อนรับ ใช้รูปปกเกม art/badges/source)
function artImage(b) {
	const data = fs.readFileSync(path.join(OUT, "source", b.art)).toString("base64");
	return `<g clip-path="url(#disc)"><image href="data:image/webp;base64,${data}" x="${b.artX}" y="${b.artY}" width="${b.artSize}" height="${b.artSize}"/></g>`;
}

function background(cat) {
	if (cat === "level") {
		let dots = "";
		for (const [x, y, r] of [[110, 130, 6], [168, 92, 4], [352, 92, 5], [410, 150, 4], [96, 250, 4], [420, 262, 6], [150, 318, 4], [372, 330, 4]]) {
			dots += `<circle cx="${x}" cy="${y}" r="${r}" fill="#ffffffcc"/>`;
		}
		return `<circle cx="256" cy="256" r="206" fill="url(#dusk)"/><g clip-path="url(#disc)">${dots}</g>`;
	}
	if (cat === "time") {
		return `<circle cx="256" cy="256" r="206" fill="url(#mint)"/>
			<g clip-path="url(#disc)">
				<circle cx="256" cy="226" r="168" fill="#ffffff22"/>
				<ellipse cx="256" cy="430" rx="240" ry="90" fill="#ffffff33"/>
			</g>`;
	}
	if (cat === "egg") {
		return `<circle cx="256" cy="256" r="206" fill="url(#barn)"/>
			<g clip-path="url(#disc)">
				<g fill="none" stroke="#ffffff33" stroke-width="7">
					<path d="M40,120 H480 M40,190 H480 M40,260 H480 M170,50 V120 M340,50 V120 M250,120 V190 M90,120 V190 M420,120 V190 M170,190 V260 M340,190 V260"/>
				</g>
				<path d="M40,340 Q256,300 480,340 V480 H40Z" fill="#f2c866"/>
			</g>`;
	}
	if (cat === "plant") {
		return `<circle cx="256" cy="256" r="206" fill="url(#sky)"/>
			<g clip-path="url(#disc)">
				<ellipse cx="170" cy="150" rx="46" ry="20" fill="#fff" opacity=".85"/>
				<ellipse cx="350" cy="118" rx="36" ry="16" fill="#fff" opacity=".85"/>
				<path d="M40,320 Q170,250 280,306 T480,290 V480 H40Z" fill="#a8e36f"/>
				<path d="M40,360 Q200,300 480,350 V480 H40Z" fill="#7fce55"/>
			</g>`;
	}
	return `<circle cx="256" cy="256" r="206" fill="url(#water)"/>
		<g clip-path="url(#disc)" fill="none" stroke="#ffffff55" stroke-width="9" stroke-linecap="round">
			<path d="M60,140 q40,-22 80,0 t80,0"/>
			<path d="M280,92 q36,-20 72,0 t72,0"/>
			<path d="M300,340 q36,-20 72,0 t72,0"/>
			<path d="M60,316 q36,-20 72,0"/>
		</g>`;
}

function studs() {
	let out = "";
	for (let i = 0; i < 28; i++) {
		const deg = i * (360 / 28);
		// ด้านบนเว้นให้ดาว ด้านล่างเว้นให้ริบบิ้น
		if (deg < 44 || deg > 316 || (deg > 118 && deg < 242)) continue;
		const a = ((deg - 90) * Math.PI) / 180;
		out += `<circle cx="${(256 + 232 * Math.cos(a)).toFixed(1)}" cy="${(256 + 232 * Math.sin(a)).toFixed(1)}" r="7" fill="#ffffffaa" stroke="#00000033" stroke-width="2"/>`;
	}
	return out;
}

function rankStars(tier) {
	if (TIERS[tier].hearts) {
		return heart(198, 46, 19, "#ff5f8f") + heart(256, 35, 23, "#ff5f8f") + heart(314, 46, 19, "#ff5f8f");
	}
	const n = TIERS[tier].stars;
	const gap = 17; // องศาระหว่างดาว
	let out = "";
	for (let i = 0; i < n; i++) {
		const deg = (i - (n - 1) / 2) * gap;
		const a = ((deg - 90) * Math.PI) / 180;
		out += star(256 + 231 * Math.cos(a), 256 + 231 * Math.sin(a), 24, "#fff3a0");
	}
	return out;
}

function ribbon(label, t, thai) {
	const size = thai ? 46 : label.length >= 4 ? 58 : 66;
	const family = thai ? "'Leelawadee UI','Leelawadee',sans-serif" : FONT;
	return `<g>
		<path d="M150,384 L84,384 L104,412 L84,440 L150,440Z" fill="${t.dark}" stroke="${INK}" stroke-width="8" stroke-linejoin="round"/>
		<path d="M362,384 L428,384 L408,412 L428,440 L362,440Z" fill="${t.dark}" stroke="${INK}" stroke-width="8" stroke-linejoin="round"/>
		<rect x="122" y="372" width="268" height="76" rx="20" fill="${t.ribbon}" stroke="${INK}" stroke-width="8"/>
		<rect x="134" y="381" width="244" height="16" rx="8" fill="#ffffff44"/>
		<text x="256" y="${thai ? 427 : 434}" text-anchor="middle" font-family="${family}" font-size="${size}" font-weight="900"
			fill="#fff" stroke="${INK}" stroke-width="11" stroke-linejoin="round" paint-order="stroke">${label}</text>
	</g>`;
}

function badgeSvg(b) {
	const t = TIERS[b.tier];
	return `<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
	<defs>
		<linearGradient id="rim" x1="0" y1="0" x2="1" y2="1">
			<stop offset="0" stop-color="${t.light}"/><stop offset=".3" stop-color="${t.mid}"/>
			<stop offset=".55" stop-color="${t.light}"/><stop offset=".8" stop-color="${t.mid}"/>
			<stop offset="1" stop-color="${t.dark}"/>
		</linearGradient>
		<linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8fdcff"/><stop offset="1" stop-color="#e6fbff"/></linearGradient>
		<linearGradient id="water" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7fe3f5"/><stop offset="1" stop-color="#1f8fd6"/></linearGradient>
		<linearGradient id="barn" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ffb37a"/><stop offset="1" stop-color="#e8704a"/></linearGradient>
		<linearGradient id="gold" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#fff0a0"/><stop offset=".5" stop-color="#ffc62e"/><stop offset="1" stop-color="#e0940f"/></linearGradient>
		<linearGradient id="dusk" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#6a5cf0"/><stop offset="1" stop-color="#c77dff"/></linearGradient>
		<linearGradient id="mint" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3fc8b8"/><stop offset="1" stop-color="#a6f0d8"/></linearGradient>
		<linearGradient id="up" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#b6f56a"/><stop offset="1" stop-color="#3fbf5a"/></linearGradient>
		<linearGradient id="leaf" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#a9ec6c"/><stop offset="1" stop-color="#55bf4a"/></linearGradient>
		<clipPath id="disc"><circle cx="256" cy="256" r="206"/></clipPath>
		<filter id="sticker" x="-20%" y="-20%" width="140%" height="140%">
			<feMorphology in="SourceAlpha" operator="dilate" radius="7" result="fat"/>
			<feFlood flood-color="#ffffff"/><feComposite in2="fat" operator="in" result="edge"/>
			<feOffset in="fat" dy="7" result="low"/><feFlood flood-color="#00000055"/><feComposite in2="low" operator="in" result="shadow"/>
			<feMerge><feMergeNode in="shadow"/><feMergeNode in="edge"/><feMergeNode in="SourceGraphic"/></feMerge>
		</filter>
	</defs>
	<rect width="512" height="512" fill="${t.mid}"/>
	<circle cx="256" cy="256" r="256" fill="url(#rim)"/>
	${studs()}
	<circle cx="256" cy="256" r="212" fill="${t.dark}" stroke="${INK}" stroke-width="6"/>
	${b.art ? artImage(b) : background(b.cat)}
	<circle cx="256" cy="256" r="206" fill="none" stroke="#ffffff66" stroke-width="5"/>
	${!b.art && BEHIND[b.icon] ? BEHIND[b.icon]() : ""}
	${b.art ? "" : `<g filter="url(#sticker)">${ICONS[b.icon]()}</g>`}
	${!b.art && EXTRAS[b.icon] ? EXTRAS[b.icon]() : ""}
	${rankStars(b.tier)}
	${ribbon(b.label, t, b.thai)}
</svg>`;
}

// ---------- รายการตรา ----------
const BADGES = [
	{ file: "plant_1_10", cat: "plant", tier: 1, label: "10", icon: "plant1" },
	{ file: "plant_2_100", cat: "plant", tier: 2, label: "100", icon: "plant2" },
	{ file: "plant_3_1K", cat: "plant", tier: 3, label: "1,000", icon: "plant3" },
	{ file: "plant_4_10K", cat: "plant", tier: 4, label: "10,000", icon: "plant4" },
	{ file: "fish_1_10", cat: "fish", tier: 1, label: "10", icon: "fish1" },
	{ file: "fish_2_100", cat: "fish", tier: 2, label: "100", icon: "fish2" },
	{ file: "fish_3_1K", cat: "fish", tier: 3, label: "1,000", icon: "fish3" },
	{ file: "egg_1_10", cat: "egg", tier: 1, label: "10", icon: "egg1" },
	{ file: "egg_2_100", cat: "egg", tier: 2, label: "100", icon: "egg2" },
	{ file: "egg_3_1K", cat: "egg", tier: 3, label: "1,000", icon: "egg3" },
	{ file: "level_1_10", cat: "level", tier: 1, label: "Lv.10", icon: "level1" },
	{ file: "level_2_50", cat: "level", tier: 2, label: "Lv.50", icon: "level2" },
	{ file: "level_3_100", cat: "level", tier: 3, label: "Lv.100", icon: "level3" },
	{ file: "time_1_10h", cat: "time", tier: 1, label: "10 ชั่วโมง", icon: "time1", thai: true },
	{ file: "time_2_50h", cat: "time", tier: 2, label: "50 ชั่วโมง", icon: "time2", thai: true },
	{ file: "welcome", cat: "plant", tier: "welcome", label: "ยินดีต้อนรับ", icon: "welcome", thai: true, art: "welcome_art.webp", artX: 36, artY: 34, artSize: 440 },
];

function shot(htmlPath, pngPath, w, h) {
	execFileSync(CHROME, [
		"--headless=new", "--disable-gpu", "--hide-scrollbars", "--force-device-scale-factor=1",
		`--window-size=${w},${h}`, `--screenshot=${pngPath}`, "file:///" + htmlPath.replace(/\\/g, "/"),
	], { stdio: "ignore" });
}

for (const dir of ["svg", "png"]) fs.mkdirSync(path.join(OUT, dir), { recursive: true });
const tmp = path.join(OUT, "_render.html");
for (const b of BADGES) {
	const svg = badgeSvg(b);
	fs.writeFileSync(path.join(OUT, "svg", b.file + ".svg"), svg);
	fs.writeFileSync(tmp, `<!doctype html><html><head><meta charset="utf-8"></head><body style="margin:0;overflow:hidden">${svg}</body></html>`);
	shot(tmp, path.join(OUT, "png", b.file + ".png"), 512, 512);
}

// แผ่นตัวอย่าง: แถวบน = ตัดวงกลมแบบ Roblox, แถวล่าง = ขนาดเล็กบนหน้าเกม
const big = BADGES.map((b) => `<img src="png/${b.file}.png" style="width:300px;height:300px;border-radius:50%">`).join("");
const small = BADGES.map((b) => `<img src="png/${b.file}.png" style="width:100px;height:100px;border-radius:50%">`).join("");
fs.writeFileSync(tmp, `<!doctype html><html><body style="margin:0;padding:28px;background:#e3e5e8;overflow:hidden">
	<div style="display:flex;flex-wrap:wrap;gap:24px">${big}</div>
	<div style="display:flex;flex-wrap:wrap;gap:24px;margin-top:28px">${small}</div></body></html>`);
shot(tmp, path.join(OUT, "preview.png"), 2000, 1270);
fs.unlinkSync(tmp);
console.log("done", BADGES.length);
