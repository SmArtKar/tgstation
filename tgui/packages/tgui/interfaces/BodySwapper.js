import { useBackend } from '../backend';
import { Section, Box, Button, LabeledList, Icon } from '../components';
import { COLORS } from '../constants';
import { Window } from '../layouts';

const statusMap = {
  Dead: "bad",
  Unconscious: "average",
  Conscious: "good",
};

const HEALTH_COLOR_BY_LEVEL = [
  '#17d568',
  '#c4cf2d',
  '#e67e22',
  '#ed5100',
  '#e74c3c',
  '#801308',
];

const HEALTH_ICON_BY_LEVEL = [
  'heart',
  'heart',
  'heart',
  'heart',
  'heartbeat',
  'skull',
];

const healthToAttribute = (oxy, tox, burn, brute, attributeList) => {
  const healthSum = oxy + tox + burn + brute;
  const level = Math.min(Math.max(Math.ceil(healthSum / 25), 0), 5);
  return attributeList[level];
};

const HealthStat = props => {
  const { type, value } = props;
  return (
    <Box
      inline
      width={2}
      color={COLORS.damageType[type]}
      textAlign="center">
      {value}
    </Box>
  );
};

export const BodySwapper = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    bodies = [],
  } = data;
  return (
    <Window
      width={400}
      height={425}>
      <Window.Content scrollable>
        {bodies.map(body => (
          <Section key={body.ref} title={(
            <Box inline color={body.name_color}>
              {body.name}
            </Box>
          )} buttons={(
            <Button
              content={body.occupied}
              selected={body.occupied === "Current body"}
              color={(body.occupied !== "Free" && body.occupied !== "Current body") && 'bad'}
              disabled={!body.swappable}
              onClick={() => act('swap', { ref: body.ref })}
            />
          )}>
            <LabeledList>
              <LabeledList.Item
                label="Status"
                bold
                color={statusMap[body.status]}>
                {body.status}
              </LabeledList.Item>
              <LabeledList.Item label="Location">
                {body.area}
              </LabeledList.Item>
              {!!(body.type === "human") && (
                <>
                  <LabeledList.Item label="Blood Volume">
                    {body.blood_volume}
                  </LabeledList.Item>
                  <LabeledList.Item>
                    <Icon
                      name={healthToAttribute(
                        body.oxy,
                        body.toxin,
                        body.burn,
                        body.brute,
                        HEALTH_ICON_BY_LEVEL)}
                      color={healthToAttribute(
                        body.oxy,
                        body.toxin,
                        body.burn,
                        body.brute,
                        HEALTH_COLOR_BY_LEVEL)}
                      size={1} />
                    <Box inline>
                      <HealthStat type="oxy" value={body.oxy} />
                      {'/'}
                      <HealthStat type="toxin" value={body.toxin} />
                      {'/'}
                      <HealthStat type="burn" value={body.burn} />
                      {'/'}
                      <HealthStat type="brute" value={body.brute} />
                    </Box>
                  </LabeledList.Item>
                </>
              )}
            </LabeledList>
          </Section>
        ))}
      </Window.Content>
    </Window>
  );
};
