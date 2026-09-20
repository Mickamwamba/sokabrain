import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { competitionDisplayName, countryShortName } from './competitionName.js';

describe('countryShortName', () => {
  it('takes the common name out of an ISO long form', () => {
    assert.equal(countryShortName('Tanzania, United Republic of'), 'Tanzania');
    assert.equal(countryShortName('Congo, the Democratic Republic of the'), 'Congo');
  });

  it('leaves a plain country name alone', () => {
    assert.equal(countryShortName('Kenya'), 'Kenya');
    assert.equal(countryShortName('South Africa'), 'South Africa');
  });

  it('returns null for no country', () => {
    assert.equal(countryShortName(null), null);
    assert.equal(countryShortName(undefined), null);
    assert.equal(countryShortName(''), null);
  });
});

describe('competitionDisplayName', () => {
  it('disambiguates the three leagues called "Premier League"', () => {
    assert.equal(competitionDisplayName('Premier League', 'Uganda'), 'Uganda Premier League');
    assert.equal(
      competitionDisplayName('Premier League', 'South Africa'),
      'South Africa Premier League',
    );
    assert.equal(
      competitionDisplayName('Premier League', 'Tanzania, United Republic of'),
      'Tanzania Premier League',
    );
  });

  it('does not repeat a country the name already begins with', () => {
    // The legacy Kenyan record is literally called "Kenya premier league".
    assert.equal(competitionDisplayName('Kenya premier league', 'Kenya'), 'Kenya premier league');
  });

  it('does not repeat a country the name contains, whatever the casing', () => {
    assert.equal(competitionDisplayName('KENYA FA CUP', 'Kenya'), 'KENYA FA CUP');
  });

  it('leaves a competition with no country alone', () => {
    assert.equal(competitionDisplayName('Africa Cup of Nations', null), 'Africa Cup of Nations');
    assert.equal(competitionDisplayName('CAF CONFEDERATION', undefined), 'CAF CONFEDERATION');
  });

  it('prefixes a name that merely shares a word with its country', () => {
    // "South Africa" is the country; "African Cup" is not the same token run.
    assert.equal(
      competitionDisplayName('African Champions Cup', 'South Africa'),
      'South Africa African Champions Cup',
    );
  });

  it('matches a multi-word country as a whole, not word by word', () => {
    assert.equal(
      competitionDisplayName('South Africa Premier Division', 'South Africa'),
      'South Africa Premier Division',
    );
  });
});
